import os

import src.ingestion.github


def main() -> int:
    src.ingestion.github.github_pipeline(
        access_token=os.environ["GITHUB_API_TOKEN"],
        username="billwallis",
    )

    return 0


if __name__ == "__main__":
    main()  # pragma: no cover
