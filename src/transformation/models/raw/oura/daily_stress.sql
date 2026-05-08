model (
    name warehouse.raw_oura.daily_stress,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,

        day_summary varchar,
        recovery_high integer,
        stress_high integer,

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

    day_summary,
    recovery_high,
    stress_high,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.daily_stress
;
