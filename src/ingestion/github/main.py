import functools
import json
import logging
import os
import pathlib
from collections.abc import Generator

import dlt
from dlt.common.typing import DictStrAny, StrAny
from dlt.sources import DltResource
from dlt.sources.helpers import requests

GRAPHQL_API_BASE_URL = "https://api.github.com/graphql"
DEFAULT_TIMEOUT_SECONDS = 60
MAX_TIMEOUT_SECONDS = 60 * 60  # 1 hour
DEFAULT_PAGE_SIZE = 50
DEFAULT_MAX_ITEMS = 1_000
HERE = pathlib.Path(__file__).parent
QUERIES = HERE / "queries"

logger = logging.getLogger("ingestion")


@functools.cache
def _read_query(query_name: str) -> str:
    return (QUERIES / query_name).read_text(encoding="utf-8")


def _auth_header(access_token: str) -> StrAny:
    return {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }


def _extract_node_type(data: StrAny, node_type: str) -> StrAny:
    def _walk_dict(dict_: StrAny) -> StrAny:
        try:
            return dict_[node_type]
        except TypeError:
            return {}
        except KeyError:
            for k in dict_.values():
                if node_info := _walk_dict(k):
                    return node_info
            return {}

    return _walk_dict(data)


def _run_graphql_query(
    access_token: str,
    query: str,
    variables: DictStrAny,
) -> tuple[StrAny, StrAny]:
    def _request() -> requests.Response:
        return requests.post(
            url=GRAPHQL_API_BASE_URL,
            headers=_auth_header(access_token),
            json={"query": query, "variables": variables},
            timeout=DEFAULT_TIMEOUT_SECONDS,
        )

    response = _request().json()
    if errors := response.get("errors"):
        logger.error(
            json.dumps(
                {"errors": errors, "variables": variables},
                indent=2,
            ),
        )

    data = response.get("data", {}) or {}
    rate_limit = data.pop("rateLimit", {"cost": 0, "remaining": 0})

    return data, rate_limit


def _get_graphql_pages(
    access_token: str,
    query: str,
    variables: DictStrAny,
    node_type: str,
) -> Generator[StrAny]:
    items_count = 0
    while True:
        response_data, _ = _run_graphql_query(access_token, query, variables)
        data = _extract_node_type(response_data, node_type)
        items = data.get("nodes", data.get("edges", []))
        if items:
            yield response_data
        else:
            break

        variables["cursor"] = data["pageInfo"]["endCursor"]
        items_count += len(items)
        if items_count >= DEFAULT_MAX_ITEMS:
            logger.error(
                f"Max items limit reached: {items_count} >= {DEFAULT_MAX_ITEMS}",
            )
            break


@dlt.resource(
    name="user",
    write_disposition="replace",
)
def user(connection_details: list[tuple[str, str]]) -> Generator[StrAny]:
    """
    Retrieve user details.
    """

    for access_token, username in connection_details:
        logger.info(f"Extracting details for {username}")
        data, _ = _run_graphql_query(
            access_token=access_token,
            query=_read_query("user.graphql"),
            variables={"user": username},
        )
        yield data


@dlt.resource(
    name="repositories",
    write_disposition="replace",
)
def user_repositories(
    connection_details: list[tuple[str, str]],
) -> Generator[StrAny]:
    """
    Retrieve user organisations.
    """

    for access_token, username in connection_details:
        logger.info(f"Extracting repositories for {username}")
        yield from _get_graphql_pages(
            access_token=access_token,
            query=_read_query("user-repositories.graphql"),
            variables={
                "user": username,
                "page_size": DEFAULT_PAGE_SIZE,
            },
            node_type="repositories",
        )


@dlt.source
def github_user(connection_details: list[tuple[str, str]]) -> list[DltResource]:
    """
    dlt source for GitHub user data.
    """

    return [
        user(connection_details).add_limit(
            max_time=MAX_TIMEOUT_SECONDS,
        ),
        user_repositories(connection_details).add_limit(
            max_time=MAX_TIMEOUT_SECONDS,
        ),
    ]


def github_pipeline(connection_details: list[tuple[str, str]]) -> None:
    """
    dlt pipeline for GitHub data.
    """

    pipeline = dlt.pipeline(
        pipeline_name="github",
        destination="motherduck",
        dataset_name="github_user",
    )
    run_info = pipeline.run(
        github_user(connection_details=connection_details),
    )
    logger.info(run_info)


def _test_graphql_query() -> None:
    data, _ = _run_graphql_query(
        access_token=os.environ["GITHUB_TOKEN"],
        query=_read_query("user.graphql"),
        # query=_read_query("user-repositories.graphql"),
        variables={
            "user": "billwallis",
            "page_size": DEFAULT_PAGE_SIZE,
        },
    )
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    _test_graphql_query()
