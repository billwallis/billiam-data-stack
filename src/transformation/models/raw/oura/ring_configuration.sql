model (
    name warehouse.raw_oura.ring_configuration,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,

        size integer,
        color varchar,
        firmware_version varchar,
        hardware_type varchar,
        set_up_at timestamptz,

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            id,
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

    size,
    color,
    firmware_version,
    hardware_type,
    set_up_at,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.ring_configuration
;
