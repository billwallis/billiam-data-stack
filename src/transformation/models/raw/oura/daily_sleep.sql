model (
    name warehouse.raw_oura.daily_sleep,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,
        timestamp timestamptz,

        score integer,
        contributors__deep_sleep integer,
        contributors__efficiency integer,
        contributors__latency integer,
        contributors__rem_sleep integer,
        contributors__restfulness integer,
        contributors__timing integer,
        contributors__total_sleep integer,

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            id,
            day,
            timestamp,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            id,
            day,
            timestamp,
            _dlt_id,
        ]),
    ),
);


select
    id,
    "day",
    "timestamp",

    score,
    -- contributors,
    contributors->>'$.deep_sleep' as contributors__deep_sleep,
    contributors->>'$.efficiency' as contributors__efficiency,
    contributors->>'$.latency' as contributors__latency,
    contributors->>'$.rem_sleep' as contributors__rem_sleep,
    contributors->>'$.restfulness' as contributors__restfulness,
    contributors->>'$.timing' as contributors__timing,
    contributors->>'$.total_sleep' as contributors__total_sleep,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.daily_sleep
;
