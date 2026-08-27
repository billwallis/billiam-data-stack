model (
    name warehouse.career.daily_tracker,
    kind full,
    grain (log_ts),
    columns (
        log_ts timestamp,
        project varchar,
        detail varchar,
        minutes int,
    ),
    audits (
        not_null(columns=[
            log_ts,
            project,
            detail,
            minutes,
        ]),
        unique_values(columns=[
            log_ts,
        ]),
    ),
);


select
    log_ts,
    project,
    detail,
    minutes,
from warehouse.raw_ods.daily_tracker
;
