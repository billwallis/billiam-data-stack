import os

import src.ingestion


def _ensure_env(env_var: str) -> str:
    try:
        return os.environ[env_var]
    except KeyError as e:
        err_msg = f"Missing required environment variable: {env_var}"
        raise OSError(err_msg) from e


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
    monzo_name = _ensure_env("GOOGLE_SHEETS__MONZO_TRANSACTIONS_NAME")
    finances_id = _ensure_env("GOOGLE_SHEETS__FINANCES_ID")
    finances_name = _ensure_env("GOOGLE_SHEETS__FINANCES_NAME")
    # finances_history_id = _ensure_env("GOOGLE_SHEETS__FINANCES_HISTORY_ID")
    # finances_history_name = _ensure_env("GOOGLE_SHEETS__FINANCES_HISTORY_NAME")
    src.ingestion.google_sheets.google_sheets_pipeline(
        google_service=src.ingestion.google_sheets.build_google_client_service(),
        google_sheets=[
            ("monzo_transactions", monzo_id, monzo_name),
            ("finances", finances_id, finances_name),
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

    return 0


if __name__ == "__main__":
    main()  # pragma: no cover
