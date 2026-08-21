model (
    enabled false,
    name warehouse.raw_oura.daily_spo2,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,

        breathing_disturbance_index integer,
        spo2_percentage__average decimal(6, 3),

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

    breathing_disturbance_index,
    -- spo2_percentage,
    spo2_percentage->>'$.average' as spo2_percentage__average,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.daily_spo2
;
