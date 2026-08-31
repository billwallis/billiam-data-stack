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
STATEMENT_DAY = 26
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


def _minus_one_month(date: datetime.date) -> datetime.date:
    assert date.day <= 28  # noqa: S101, PLR2004
    if date.month == 1:
        return datetime.date(
            year=date.year - 1,
            month=12,
            day=date.day,
        )
    else:
        return datetime.date(
            year=date.year,
            month=date.month - 1,
            day=date.day,
        )


def _previous_statement_date(statement_day: int) -> datetime.date:
    return _minus_one_month(datetime.date.today().replace(day=statement_day))


def _earliest_statement_date(statement_day: int) -> datetime.date:
    # Amex statements over 2 years old can't be downloaded as CSVs
    previous_statement_date = _previous_statement_date(statement_day)
    return previous_statement_date.replace(
        year=previous_statement_date.year - 2
    )


def _get_statement_dates(
    statement_day: int,
    start_date: datetime.date | None = None,
    end_date: datetime.date | None = None,
) -> list[datetime.date]:
    start_date = (
        _earliest_statement_date(statement_day)
        if start_date is None
        else start_date
    )
    end_date = (
        _previous_statement_date(statement_day)
        if end_date is None
        else end_date
    )

    dates = []
    current_date = end_date
    while current_date > start_date:
        dates.append(current_date)
        current_date = _minus_one_month(current_date)

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
            write_disposition="merge",
            primary_key="reference",
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
    # python -m src.ingestion.american_express

    # resp = _get_american_express_statement(
    #     cookie=read_cookie(),
    #     account_key=os.environ["AMEX_ACCOUNT_KEY"],
    #     statement_end_dates=["2026-03-26"],
    # )
    # for item in resp:
    #     print(item)

    statement_dates = [
        d.strftime("%Y-%m-%d")
        for d in _get_statement_dates(
            statement_day=STATEMENT_DAY,
            # end_date=datetime.date(year=2026, month=5, day=STATEMENT_DAY),
            # start_date=datetime.date(year=2026, month=3, day=STATEMENT_DAY),
        )
    ]
    print(f"Grabbing Amex statements for dates: {', '.join(statement_dates)}")
    input("Update the Amex cookie, then press Enter to continue...")
    american_express_pipeline(
        cookie=read_cookie(),
        account_key=os.environ["AMEX_ACCOUNT_KEY"],
        statement_end_dates=statement_dates,
    )
