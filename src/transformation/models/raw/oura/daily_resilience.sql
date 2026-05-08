model (
    name warehouse.raw_oura.daily_resilience,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,

        level varchar,
        contributors__sleep_recovery decimal(4, 1),
        contributors__daytime_recovery decimal(4, 1),
        contributors__stress decimal(4, 1),

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            id,
            day,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            id,
            day,
            _dlt_id,
        ]),
    ),
);


select
    id,
    "day",

    level,
    -- contributors,
    contributors->>'$.sleep_recovery' as contributors__sleep_recovery,
    contributors->>'$.daytime_recovery' as contributors__daytime_recovery,
    contributors->>'$.stress' as contributors__stress,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.daily_resilience
;
