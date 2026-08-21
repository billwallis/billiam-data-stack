model (
    enabled false,
    name warehouse.raw_oura.ring_battery_level,
    kind full,
    grain (timestamp),
    tags (oura),
    columns (
        timestamp timestamptz,

        charging boolean,
        in_charger boolean,
        level integer,
        producer_timestamp bigint,

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

    charging,
    in_charger,
    level,
    producer_timestamp,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.ring_battery_level
;
