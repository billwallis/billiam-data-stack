import logging

import dlt
import dlt.sources.rest_api
from dlt.sources import DltSource
from dlt.sources.helpers import requests
from dlt.sources.helpers.rest_client.auth import BearerTokenAuth
from dlt.sources.rest_api import EndpointResource, rest_api_source

DEFAULT_PAGE_SIZE = 100
PURE_GYM_BASE_URL = "https://capi.puregym.com/"
PURE_GYM_RESOURCES: list[EndpointResource] = [
    {
        # Gyms
        "name": "gyms",
        "endpoint": {
            "path": "api/v2/gyms",
        },
    },
    {
        # My gym
        "name": "member",
        "endpoint": {
            "path": "api/v2/member",
        },
    },
    {
        # My gym sessions
        "name": "gym_sessions",
        "endpoint": {
            "path": "api/v2/gymSessions/member",
        },
    },
]

logger = logging.getLogger("ingestion")


def _pure_gym(access_token: str) -> DltSource:
    return rest_api_source(
        name="pure_gym",
        config={
            "client": {
                "base_url": PURE_GYM_BASE_URL,
                "auth": BearerTokenAuth(access_token),
                "headers": {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                },
            },
            "resource_defaults": {
                "write_disposition": "replace",
                "max_table_nesting": 0,
                "endpoint": {
                    "data_selector": "$",
                },
            },
            "resources": PURE_GYM_RESOURCES,
        },
    )


def _get_access_token(username: str, password: str) -> str:
    response = requests.post(
        url="https://auth.puregym.com/connect/token",
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data={
            "grant_type": "password",
            "client_id": "ro.client",
            "scope": "pgcapi",
            "username": username,
            "password": password,
        },
    )

    return response.json()["access_token"]


def pure_gym_pipeline(username: str, password: str) -> None:
    """
    dlt pipeline for PureGym data.
    """

    pipeline = dlt.pipeline(
        pipeline_name="pure_gym",
        destination="motherduck",
        dataset_name="pure_gym",
    )
    access_token = _get_access_token(
        username=username,
        password=password,
    )
    run_info = pipeline.run(
        _pure_gym(access_token),
    )
    logger.info(run_info)
