import os

import src.ingestion.github
import src.ingestion.google_sheets


def _ensure_env(env_var: str) -> str:
    try:
        return os.environ[env_var]
    except KeyError as e:
        err_msg = f"Missing required environment variable: {env_var}"
        raise OSError(err_msg) from e


def main() -> int:
    _ensure_env("MOTHERDUCK_TOKEN")

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

    return 0


if __name__ == "__main__":
    main()  # pragma: no cover
