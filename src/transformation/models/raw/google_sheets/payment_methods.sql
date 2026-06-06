model (
    name warehouse.raw_google_sheets.payment_methods,
    kind full,
    grain (transaction_id, payment_method),
    tags (finances),
    columns (
        transaction_id varchar,
        payment_method varchar,
        amount decimal(18, 2),
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            transaction_id,
            payment_method,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            _dlt_id,
        ]),
    ),
);


select
    transaction_id,
    payment_method,
    translate(amount, '£,', '')::decimal(18, 2) as amount,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.google_sheets.payment_methods
;
