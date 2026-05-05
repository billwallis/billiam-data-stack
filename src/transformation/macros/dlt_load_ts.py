from typing import Any

from sqlmesh import macro


@macro()
def dlt_load_ts(evaluator, dlt_load_id: Any) -> str:  # noqa: ANN001
    """
    Convert the dlt load ID into a timestamp.
    """

    return f"make_timestamp(1000000 * {dlt_load_id}::bigint)"
