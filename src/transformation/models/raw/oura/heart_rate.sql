model (
    name warehouse.raw_oura.heart_rate,
    kind full,
    grain (timestamp),
    tags (oura),
    columns (
        timestamp timestamptz,

        bpm integer,
        producer_timestamp bigint,
        source varchar,

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            timestamp,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            timestamp,
            _dlt_id,
        ]),
    ),
);


select
    "timestamp",

    bpm,
    producer_timestamp,
    source,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.heartrate
;
