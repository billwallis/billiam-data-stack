model (
    name warehouse.raw_oura.daily_cardiovascular_age,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,

        pulse_wave_velocity double,
        vascular_age integer,

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

    pulse_wave_velocity,
    vascular_age,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.daily_cardiovascular_age
;
