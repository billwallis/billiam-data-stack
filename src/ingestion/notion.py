import logging

import dlt
import dlt.sources.rest_api
from dlt.sources import DltSource
from dlt.sources.helpers.rest_client.auth import BearerTokenAuth
from dlt.sources.helpers.rest_client.paginators import (
    JSONResponseCursorPaginator,
)
from dlt.sources.rest_api import EndpointResource, rest_api_source

NOTION_BASE_URL = "https://api.notion.com"
NOTION_VERSION = "2026-03-11"
DEFAULT_PAGE_SIZE = 100
DAILY_UPDATES_DATABASE_ID = "0ad4a6b3980540fea5fa868e4b98111b"

NOTION_RESOURCES: list[EndpointResource] = [
    {
        # https://developers.notion.com/reference/retrieve-database
        "name": "databases",
        "endpoint": {
            "path": f"/v1/databases/{DAILY_UPDATES_DATABASE_ID}",
        },
    },
    {
        # https://developers.notion.com/reference/retrieve-a-data-source
        "name": "data_sources",
        "endpoint": {
            "path": "v1/data_sources/{resources.databases.data_sources[:].id}",
        },
    },
    {
        # https://developers.notion.com/reference/query-a-data-source
        "name": "data_source_pages",
        "endpoint": {
            "method": "POST",
            "path": "v1/data_sources/{resources.databases.data_sources[:].id}/query",
            "paginator": JSONResponseCursorPaginator(
                cursor_path="next_cursor",
                cursor_body_path="start_cursor",
            ),
            "json": {
                "page_size": DEFAULT_PAGE_SIZE,
                "result_type": "page",
            },
            "data_selector": "results",
        },
    },
    # Temporarily disable until we can get _all_ the content
    # {
    #     # https://developers.notion.com/reference/get-block-children
    #     # TODO: recursively call this endpoint if the returned block has `has_children`
    #     "name": "data_source_page_content",
    #     "endpoint": {
    #         "path": "v1/blocks/{resources.data_source_pages.id}/children",
    #         "paginator": JSONResponseCursorPaginator(
    #             cursor_path="next_cursor",
    #             cursor_param="start_cursor",
    #         ),
    #         "params": {
    #             "page_size": DEFAULT_PAGE_SIZE,
    #         },
    #         "data_selector": "results",
    #     },
    # },
]

logger = logging.getLogger("ingestion")


def _notion(api_token: str) -> DltSource:
    return rest_api_source(
        name="notion",
        config={
            "client": {
                "base_url": NOTION_BASE_URL,
                "auth": BearerTokenAuth(api_token),
                "headers": {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "Notion-Version": NOTION_VERSION,
                },
            },
            "resource_defaults": {
                "write_disposition": "replace",
                "max_table_nesting": 0,
                "endpoint": {
                    "data_selector": "$",
                },
            },
            "resources": NOTION_RESOURCES,
        },
    )


def notion_pipeline(api_token: str) -> None:
    """
    dlt pipeline for Notion data.
    """

    pipeline = dlt.pipeline(
        pipeline_name="notion",
        destination="motherduck",
        dataset_name="notion",
    )
    run_info = pipeline.run(
        _notion(api_token=api_token),
    )
    logger.info(run_info)
