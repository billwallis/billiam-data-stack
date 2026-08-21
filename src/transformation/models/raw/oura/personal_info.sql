model (
    enabled false,
    name warehouse.raw_oura.personal_info,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,

        age integer,
        weight integer,
        height decimal(4, 2),
        biological_sex varchar,
        email varchar,

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

    age,
    weight,
    height,
    biological_sex,
    email,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.personal_info
;
