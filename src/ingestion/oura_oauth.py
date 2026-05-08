"""
Custom OAuth2 server for Oura:

- https://cloud.ouraring.com/docs/authentication

Largely based on the client defined by GitHub user ``turing-complet``:

- https://github.com/turing-complet/python-ouraring/tree/main

---

Set the env vars ``OURA_CLIENT_ID`` and ``OURA_CLIENT_SECRET``, then run
with::

    python -m src.ingestion.oura_oauth
"""

import datetime
import http
import json
import os
import pathlib
import signal
import threading
import urllib.parse
import webbrowser

import flask
from dlt.sources.helpers import requests

HERE = pathlib.Path(__file__).parent
SRC_PATH = HERE.parent
assert SRC_PATH.name == "src"  # noqa: S101
CLIENT_TOKEN_PATH = SRC_PATH.parent / "oura-credentials.json"
CLIENT_HOST = "localhost"
CLIENT_PORT = 3030
# noinspection HttpUrlsUsage
CLIENT_URL = f"http://{CLIENT_HOST}:{CLIENT_PORT}"

OURA_CLIENT_ID = os.environ["OURA_CLIENT_ID"]
OURA_CLIENT_SECRET = os.environ["OURA_CLIENT_SECRET"]
BASE_URL = "https://cloud.ouraring.com"
AUTHORISATION_URL = f"{BASE_URL}/oauth/authorize"
ACCESS_TOKEN_URL = f"{BASE_URL}/oauth/token"
SCOPES = [
    "email",
    "personal",
    "daily",
    "heartrate",
    "tag",
    "workout",
    "session",
    "spo2",
    "ring_configuration",
    "stress",
    "heart_health",
]

app = flask.Flask(__name__)


def _get_auth_url(client_id: str) -> str:
    params = {
        "client_id": client_id,
        "redirect_uri": urllib.parse.quote_plus(CLIENT_URL),
        "response_type": "code",
        "scope": "+".join(SCOPES),
    }
    # surely there's a stdlib function for this?
    param_url = "&".join((f"{k}={v}" for k, v in params.items()))

    return f"{AUTHORISATION_URL}?{param_url}"


def _get_auth_token(
    client_id: str, client_secret: str, auth_code: str
) -> requests.Response:
    return requests.post(
        url=ACCESS_TOKEN_URL,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
        },
        data={
            "grant_type": "authorization_code",
            "code": auth_code,
            "redirect_uri": CLIENT_URL,
            "client_id": client_id,
            "client_secret": client_secret,
        },
    )


def _shutdown() -> None:
    # https://stackoverflow.com/a/62322623
    os.kill(os.getpid(), signal.SIGKILL)


@app.route("/")
def index() -> str:
    auth_code = flask.request.args.get("code")
    if auth_code is None:
        return "<h1>Error retrieving token</h1>"

    response = _get_auth_token(OURA_CLIENT_ID, OURA_CLIENT_SECRET, auth_code)
    if response.status_code != http.HTTPStatus.OK:
        return f"<h1>Error retrieving token: {response.text}</h1>"

    creds = response.json()
    now = datetime.datetime.now()
    creds["_created_at"] = now.isoformat()
    expires_at = now + datetime.timedelta(seconds=creds["expires_in"])
    creds["_expires_at"] = expires_at.isoformat()

    with open(CLIENT_TOKEN_PATH, "w+", encoding="utf-8") as f:
        json.dump(creds, f, indent=2)

    threading.Timer(0.1, _shutdown).start()
    return "<h1>You are now authorised to access the Oura API!</h1>"


def main() -> int:
    url = _get_auth_url(OURA_CLIENT_ID)
    threading.Timer(1, webbrowser.open, args=(url,)).start()
    app.run(host=CLIENT_HOST, port=CLIENT_PORT)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
