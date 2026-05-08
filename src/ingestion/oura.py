"""
dlt pipeline definitions for Oura Ring data:

- https://cloud.ouraring.com/v2/docs#tag/Personal-Info-Routes

---

Consider using the following as additional inspiration:

- https://github.com/idalbo/oura_ring_pipeline
"""

import calendar
import datetime
import logging

import dlt
import dlt.sources.rest_api
from dlt.sources import DltSource
from dlt.sources.helpers.rest_client.auth import BearerTokenAuth
from dlt.sources.helpers.rest_client.paginators import (
    SinglePagePaginator,
)
from dlt.sources.rest_api import EndpointResource, rest_api_source

# _YEAR_MONTH = (2026, 5)
_YEAR_MONTH = tuple(
    int(p) for p in datetime.datetime.today().strftime("%Y-%m").split("-")
)
FROM_DATE = f"{_YEAR_MONTH[0]}-{_YEAR_MONTH[1]:02}-01"
UNTIL_DATE = f"{_YEAR_MONTH[0]}-{_YEAR_MONTH[1]:02}-{calendar.monthrange(*_YEAR_MONTH)[1]:02}"
# Date diff is unbounded, but timestamp diff can be no more than 31 days
# in the requests
FROM_DATETIME = f"{FROM_DATE}T00:00:00+00:00"
UNTIL_DATETIME = f"{UNTIL_DATE}T23:59:59+00:00"


OURA_BASE_URL = "https://api.ouraring.com/"
OURA_RESOURCES: list[EndpointResource] = [
    # Single-object responses
    {
        # Personal Info
        "name": "personal_info",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/personal_info",
            "data_selector": "$",
        },
    },
    {
        # Ring Configuration
        "name": "ring_configuration",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/ring_configuration",
        },
    },
    # Daily metrics
    {
        # Daily Activity
        "name": "daily_activity",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_activity",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Daily Cardiovascular Age
        "name": "daily_cardiovascular_age",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_cardiovascular_age",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Daily Readiness
        "name": "daily_readiness",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_readiness",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Daily Resilience
        "name": "daily_resilience",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_resilience",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Daily Sleep
        "name": "daily_sleep",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_sleep",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Daily SPO2
        "name": "daily_spo2",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_spo2",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Daily Stress
        "name": "daily_stress",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/daily_stress",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    # Individual metrics
    {
        # Rest Mode Period
        "name": "rest_mode_period",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/rest_mode_period",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Sleep
        "name": "sleep",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/sleep",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Sleep Time
        "name": "sleep_time",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/sleep_time",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # VO2 Max
        "name": "vO2_max",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/vO2_max",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    {
        # Workout
        "name": "workout",
        "primary_key": "id",
        "endpoint": {
            "path": "v2/usercollection/workout",
            "params": {
                "start_date": FROM_DATE,
                "end_date": UNTIL_DATE,
            },
        },
    },
    # Granular metrics
    {
        # Heartrate
        "name": "heartrate",
        "primary_key": "timestamp",
        "endpoint": {
            "path": "v2/usercollection/heartrate",
            "params": {
                "start_datetime": FROM_DATETIME,
                "end_datetime": UNTIL_DATETIME,
            },
        },
    },
    {
        # Ring Battery Level
        "name": "ring_battery_level",
        "primary_key": "timestamp",
        "endpoint": {
            "path": "v2/usercollection/ring_battery_level",
            "params": {
                "start_datetime": FROM_DATETIME,
                "end_datetime": UNTIL_DATETIME,
            },
        },
    },
    # {
    #     # Interbeat Interval  (getting a 401 :shrug:)
    #     "name": "interbeat_interval",
    #     "primary_key": "timestamp",
    #     "endpoint": {
    #         "path": "v2/usercollection/interbeat_interval",
    #         "params": {
    #             "start_datetime": FROM_DATETIME,
    #             "end_datetime": UNTIL_DATETIME,
    #         },
    #     },
    # },
]

logger = logging.getLogger("ingestion")


def _oura(access_token: str) -> DltSource:
    return rest_api_source(
        name="oura",
        config={
            "client": {
                "base_url": OURA_BASE_URL,
                "auth": BearerTokenAuth(access_token),
                "headers": {
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                },
            },
            "resource_defaults": {
                "write_disposition": "merge",
                "max_table_nesting": 0,
                "endpoint": {
                    "data_selector": "data",
                    "paginator": SinglePagePaginator(),
                },
            },
            "resources": OURA_RESOURCES,
        },
    )


def oura_pipeline(access_token: str) -> None:
    """
    dlt pipeline for Oura data.
    """

    pipeline = dlt.pipeline(
        pipeline_name="oura",
        destination="motherduck",
        dataset_name="oura",
    )
    run_info = pipeline.run(
        _oura(access_token),
    )
    logger.info(run_info)
