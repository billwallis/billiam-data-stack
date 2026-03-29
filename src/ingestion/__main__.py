import os

import src.ingestion.github


def _ensure_env(env_var: str) -> str:
    try:
        return os.environ[env_var]
    except KeyError as e:
        err_msg = f"Missing required environment variable: {env_var}"
        raise OSError(err_msg) from e


def main() -> int:
    _ensure_env("MOTHERDUCK_TOKEN")
    github_token = _ensure_env("GITHUB_API_TOKEN")

    # Run GitHub
    src.ingestion.github.github_pipeline(
        access_token=github_token,
        username="billwallis",
    )

    return 0


if __name__ == "__main__":
    main()  # pragma: no cover
