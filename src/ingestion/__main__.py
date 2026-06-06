import json
import os
import pathlib
import tomllib
from typing import Any

import src.ingestion

HERE = pathlib.Path(__file__).parent
assert HERE.parent.name == "src"  # noqa: S101


def _ensure_env(env_var: str) -> str:
    try:
        return os.environ[env_var]
    except KeyError as e:
        err_msg = f"Missing required environment variable: {env_var}"
        raise OSError(err_msg) from e


def _read_credentials_file(
    file: pathlib.Path,
    key: str,
) -> Any:
    if file.suffix == ".json":
        with open(file, encoding="utf-8") as f:
            contents = json.load(f)
    elif file.suffix == ".toml":
        with open(file, "rb") as f:
            contents = tomllib.load(f)
    else:
        raise ValueError(f"Unsupported credentials file type: {file.suffix}")

    return contents[key]


def main() -> int:
    _ensure_env("MOTHERDUCK_TOKEN")

    # # Run Amex
    # amex_account_key = _ensure_env("AMEX_ACCOUNT_KEY")
    # src.ingestion.american_express.american_express_pipeline(
    #     cookie=src.ingestion.american_express.read_cookie(),
    #     account_key=amex_account_key,
    #     statement_end_dates=[],
    # )

    # Run GitHub
    github_token = _ensure_env("GITHUB_API_TOKEN")
    src.ingestion.github.github_pipeline(
        access_token=github_token,
        username="billwallis",
    )

    # Run Google Sheets
    monzo_id = _ensure_env("GOOGLE_SHEETS__MONZO_TRANSACTIONS_ID")
    monzo_personal = _ensure_env("GOOGLE_SHEETS__MONZO_TRANSACTIONS_PERSONAL")
    monzo_joint = _ensure_env("GOOGLE_SHEETS__MONZO_TRANSACTIONS_JOINT")
    finances_id = _ensure_env("GOOGLE_SHEETS__FINANCES_ID")
    finances_log = _ensure_env("GOOGLE_SHEETS__FINANCES_LOG")
    finances_payment_methods = _ensure_env(
        "GOOGLE_SHEETS__FINANCES_PAYMENT_METHODS"
    )
    # finances_history_id = _ensure_env("GOOGLE_SHEETS__FINANCES_HISTORY_ID")
    # finances_history_name = _ensure_env("GOOGLE_SHEETS__FINANCES_HISTORY_NAME")
    src.ingestion.google_sheets.google_sheets_pipeline(
        google_service=src.ingestion.google_sheets.build_google_client_service(),
        google_sheets=[
            ("monzo_transactions", monzo_id, monzo_personal),
            ("monzo_transactions_joint", monzo_id, monzo_joint),
            ("finances", finances_id, finances_log),
            ("payment_methods", finances_id, finances_payment_methods),
            # ("finances_history", finances_history_id, finances_history_name),
        ],
    )

    # Run Notion
    notion_token = _ensure_env("NOTION_API_TOKEN")
    src.ingestion.notion.notion_pipeline(api_token=notion_token)

    # Run PureGym
    pure_gym_username = _ensure_env("PURE_GYM_USERNAME")
    pure_gym_password = _ensure_env("PURE_GYM_PASSWORD")
    src.ingestion.pure_gym.pure_gym_pipeline(
        username=pure_gym_username,
        password=pure_gym_password,
    )

    # Run Oura
    oura_access_token = _read_credentials_file(
        file=HERE.parent.parent / "oura-credentials.json",
        key="access_token",
    )
    assert isinstance(oura_access_token, str)  # noqa: S101
    src.ingestion.oura.oura_pipeline(
        access_token=oura_access_token,
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())  # pragma: no cover
