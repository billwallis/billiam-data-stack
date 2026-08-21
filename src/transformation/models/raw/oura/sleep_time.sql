model (
    enabled false,
    name warehouse.raw_oura.sleep_time,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,

        status varchar,
        recommendation varchar,
        optimal_bedtime__day_tz integer,
        optimal_bedtime__start_offset integer,
        optimal_bedtime__end_offset integer,

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

    status,
    recommendation,
    -- optimal_bedtime,
    optimal_bedtime->>'$.day_tz' as optimal_bedtime__day_tz,
    optimal_bedtime->>'$.start_offset' as optimal_bedtime__start_offset,
    optimal_bedtime->>'$.end_offset' as optimal_bedtime__end_offset,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.sleep_time
;
