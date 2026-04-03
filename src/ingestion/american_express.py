import csv
import datetime
import itertools
import logging
import os
import pathlib
from collections.abc import Generator

import dlt
from dlt.common.typing import StrAny
from dlt.sources import DltResource
from dlt.sources.helpers import requests

HERE = pathlib.Path(__file__).parent
START_DATE = datetime.date(year=2023, month=11, day=26)
BASE_URL = "https://global.americanexpress.com/api/servicing/v1"
PARAMS = {
    "file_format": "csv",
    "limit": "all",
    "status": "posted",
    "additional_fields": True,
    "client_id": "AmexAPI",
}

logger = logging.getLogger("ingestion")


def read_cookie() -> str:
    # Get the cookie from the header of a manually downloaded CSV
    return (HERE / "amex-cookie").read_text().strip()


def _plus_one_month(date: datetime.date) -> datetime.date:
    assert date.day <= 28  # noqa: S101, PLR2004
    if date.month == 12:  # noqa: PLR2004
        return datetime.date(
            year=date.year + 1,
            month=1,
            day=date.day,
        )
    else:
        return datetime.date(
            year=date.year,
            month=date.month + 1,
            day=date.day,
        )


def _get_statement_dates(
    start_date: datetime.date,
    end_date: datetime.date,
) -> list[datetime.date]:
    dates = []
    current_date = start_date
    while current_date < end_date:
        dates.append(current_date)
        current_date = _plus_one_month(current_date)

    return dates


def _csv_to_json(data: str) -> Generator[StrAny]:
    reader = csv.reader(data.splitlines())
    headers = next(reader)
    for row in reader:
        yield {h: v for h, v in itertools.zip_longest(headers, row)}


def _get_american_express_statement(
    cookie: str,
    account_key: str,
    statement_end_dates: list[str],
) -> Generator[StrAny]:
    endpoint = f"{BASE_URL}/financials/documents"
    for statement_date in statement_end_dates:
        params = {
            "account_key": account_key,
            "statement_end_date": statement_date,
        } | PARAMS
        response = requests.get(
            url=endpoint,
            params=params,
            headers={"Cookie": cookie},
        )
        yield from _csv_to_json(response.text)


@dlt.source
def _american_express(
    cookie: str,
    account_key: str,
    statement_end_dates: list[str],
) -> list[DltResource]:
    return [
        dlt.resource(
            _get_american_express_statement(
                cookie=cookie,
                account_key=account_key,
                statement_end_dates=statement_end_dates,
            ),
            name="american_express_statements",
            write_disposition="replace",
        )
    ]


def american_express_pipeline(
    cookie: str,
    account_key: str,
    statement_end_dates: list[str],
) -> None:
    """
    dlt pipeline for American Express data.
    """

    pipeline = dlt.pipeline(
        pipeline_name="amex",
        destination="motherduck",
        dataset_name="american_express",
    )
    run_info = pipeline.run(
        _american_express(
            cookie=cookie,
            account_key=account_key,
            statement_end_dates=statement_end_dates,
        ),
    )
    logger.info(run_info)


if __name__ == "__main__":
    # https://global.americanexpress.com/activity/statements
    # uv run -m src.ingestion.american_express

    # resp = _get_american_express_statement(
    #     cookie=read_cookie(),
    #     account_key=os.environ["AMEX_ACCOUNT_KEY"],
    #     statement_end_dates=["2026-03-26"],
    # )
    # for item in resp:
    #     print(item)

    statement_dates = _get_statement_dates(
        start_date=START_DATE,
        end_date=datetime.date.today(),
    )
    american_express_pipeline(
        cookie=read_cookie(),
        account_key=os.environ["AMEX_ACCOUNT_KEY"],
        statement_end_dates=[str(d) for d in statement_dates],
    )
