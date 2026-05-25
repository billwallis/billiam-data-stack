from __future__ import annotations

import dataclasses
import datetime
import pathlib
from typing import Any

import google_auth_oauthlib.flow
from google.auth.transport import requests
from google.oauth2 import credentials
from googleapiclient import discovery

HERE = pathlib.Path(__file__).parent
CREDENTIALS_FILE = HERE / "credentials.json"
TOKEN_FILE = HERE / "token.json"
SCOPES = ["https://www.googleapis.com/auth/gmail.readonly"]


def _get_from_list_by_name(data: list[dict], name: str) -> Any:
    for item in data:
        if item["name"] == name:
            return item["value"]
    raise KeyError(f"{name!r} not found in {data}")


@dataclasses.dataclass
class EmailPayload:
    date: str
    subject: str
    from_contact: str
    body: str = dataclasses.field(repr=False)
    # parts: list[dict] = dataclasses.field(repr=False)
    # mime_type: str = dataclasses.field(repr=False)
    _headers: list[dict] = dataclasses.field(repr=False)

    @classmethod
    def from_json(cls, data: dict) -> EmailPayload:
        headers = data["headers"]
        return cls(
            date=_get_from_list_by_name(headers, "Date"),
            subject=_get_from_list_by_name(headers, "Subject"),
            from_contact=_get_from_list_by_name(headers, "From"),
            body=data["body"].get("data", ""),
            # parts=data.get("parts", []),
            # mime_type=data["mimeType"],
            _headers=headers,
        )


@dataclasses.dataclass
class EmailMessage:
    id: str
    label_ids: list[str]
    snippet: str
    internal_date: datetime.datetime
    payload: EmailPayload

    @classmethod
    def from_json(cls, data: dict) -> EmailMessage:
        return cls(
            id=data["id"],
            label_ids=data["labelIds"],
            snippet=data["snippet"],
            internal_date=datetime.datetime.fromtimestamp(
                int(data["internalDate"]) / 1_000
            ),
            payload=EmailPayload.from_json(data["payload"]),
        )


def _get_credentials() -> credentials.Credentials:
    """
    Authenticate the user and return Google API credentials.

    Taken from:

    - https://developers.google.com/workspace/gmail/api/quickstart/python#configure_the_sample
    """

    creds = None
    if TOKEN_FILE.exists():
        creds = credentials.Credentials.from_authorized_user_file(
            filename=str(TOKEN_FILE),
            scopes=SCOPES,
        )

    if creds and creds.valid:
        return creds

    if creds and creds.expired and creds.refresh_token:
        creds.refresh(requests.Request())

    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        client_secrets_file=str(CREDENTIALS_FILE),
        scopes=SCOPES,
    )
    creds = flow.run_local_server(port=0)

    TOKEN_FILE.write_text(creds.to_json())

    return creds


def _build_service(creds: credentials.Credentials) -> discovery.Resource:
    return discovery.build(
        serviceName="gmail",
        version="v1",
        credentials=creds,
    )


def _get_google_main_inbox_emails() -> list[EmailMessage]:
    users = _build_service(_get_credentials()).users()  # type: ignore
    return [
        EmailMessage.from_json(
            users.messages().get(userId="me", id=result["id"]).execute()
        )
        for result in (
            users.messages()
            .list(userId="me", labelIds=["INBOX"])
            .execute()
            .get("messages", [])
        )
    ]


def main() -> int:
    for result in _get_google_main_inbox_emails():
        print(result)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
