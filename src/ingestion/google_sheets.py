import itertools
import json
import logging
import os
import pathlib
from collections.abc import Generator

import dlt
import google_auth_oauthlib.flow
from dlt.common.typing import StrAny
from dlt.sources import DltResource
from google.auth.transport import requests
from google.oauth2 import credentials
from googleapiclient import discovery

HERE = pathlib.Path(__file__)
SRC_ROOT = HERE.parent.parent
assert SRC_ROOT.name == "src"  # noqa: S101
PROJECT_ROOT = SRC_ROOT.parent

SCOPES = ["https://www.googleapis.com/auth/spreadsheets.readonly"]
CREDENTIALS_FILE = PROJECT_ROOT / "credentials.json"
TOKEN_FILE = PROJECT_ROOT / "token.json"

logger = logging.getLogger("ingestion")


def _create_credentials_files(
    project_id: str,
    client_id: str,
    client_secret: str,
) -> None:
    creds = {
        "installed": {
            "project_id": project_id,
            "client_id": client_id,
            "client_secret": client_secret,
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "redirect_uris": ["http://localhost"],
        }
    }
    with open(CREDENTIALS_FILE, "w+", encoding="utf-8") as f:
        json.dump(creds, f)


def _get_credentials() -> credentials.Credentials:
    """
    Authenticate the user and return Google API credentials.

    Taken from:

    - https://developers.google.com/workspace/calendar/api/quickstart/python#configure_the_sample
    """

    if not CREDENTIALS_FILE.exists():
        _create_credentials_files(
            project_id=os.environ["GOOGLE_API_PROJECT_ID"],
            client_id=os.environ["GOOGLE_API_CLIENT_ID"],
            client_secret=os.environ["GOOGLE_API_CLIENT_SECRET"],
        )

    if TOKEN_FILE.exists():
        creds = credentials.Credentials.from_authorized_user_file(
            filename=str(TOKEN_FILE),
            scopes=SCOPES,
        )
    else:
        creds = None

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            # This raises `google.auth.exceptions.TransportError` if no internet
            creds.refresh(requests.Request())
        else:
            flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
                client_secrets_file=str(CREDENTIALS_FILE),
                scopes=SCOPES,
            )
            creds = flow.run_local_server(port=0)

        # Save the credentials for the next run
        TOKEN_FILE.write_text(creds.to_json())

    return creds


def _build_service(creds: credentials.Credentials) -> discovery.Resource:
    return discovery.build(
        serviceName="sheets",
        version="v4",
        credentials=creds,
    )


def build_google_client_service() -> discovery.Resource:
    return _build_service(_get_credentials())


def _get_google_sheet_data(
    google_service: discovery.Resource,
    sheet_id: str,
    sheet_name: str,
) -> Generator[StrAny]:
    results = (
        google_service.spreadsheets()  # type: ignore
        .values()
        .get(spreadsheetId=sheet_id, range=sheet_name)
        .execute()
        .get("values", [])
    )

    headers = results[0]
    for row in results[1:]:
        yield {h: v for h, v in itertools.zip_longest(headers, row)}


@dlt.source
def _google_spreadsheets(
    google_service: discovery.Resource,
    google_sheets: list[tuple[str, str, str]],
) -> list[DltResource]:
    return [
        dlt.resource(
            _get_google_sheet_data(
                google_service=google_service,
                sheet_id=sheet_id,
                sheet_name=sheet_name,
            ),
            name=name,
            write_disposition="replace",
        )
        for name, sheet_id, sheet_name in google_sheets
    ]


def google_sheets_pipeline(
    google_service: discovery.Resource,
    google_sheets: list[tuple[str, str, str]],
) -> None:
    """
    dlt pipeline for Google Sheet data.
    """

    pipeline = dlt.pipeline(
        pipeline_name="google_spreadsheets",
        destination="motherduck",
        dataset_name="google_sheets",
    )
    run_info = pipeline.run(
        _google_spreadsheets(
            google_service=google_service,
            google_sheets=google_sheets,
        ),
    )
    logger.info(run_info)
