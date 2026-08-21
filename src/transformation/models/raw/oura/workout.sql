model (
    enabled false,
    name warehouse.raw_oura.workout,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        start_datetime timestamptz,
        end_datetime timestamptz,

        day date,
        activity varchar,
        calories double,
        intensity varchar,
        label varchar,
        source varchar,
        distance double,

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            id,
            start_datetime,
            end_datetime,
            day,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            id,
            _dlt_id,
        ]),
    ),
);


select
    id,
    start_datetime,
    end_datetime,

    "day",
    activity,
    calories,
    intensity,
    label,
    source,
    distance,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.workout
;
