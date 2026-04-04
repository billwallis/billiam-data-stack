model (
    name warehouse.raw_american_express.amex_transactions,
    kind full,
    grain (transaction_id),
    tags (finances),
    columns (
        transaction_id varchar,
        transaction_date date,
        description varchar,
        card_member varchar,
        accountx varchar,
        cost decimal(18, 2),
        notes varchar,
        appears_on_your_statement_as varchar,
        address_lines varchar,
        city varchar,
        postcode varchar,
        country varchar,
        category varchar,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            transaction_id,
            transaction_date,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            transaction_id,
            _dlt_id,
        ]),
    ),
);


select
    trim(reference) as transaction_id,

    strptime("date", '%d/%m/%Y')::date as transaction_date,
    trim(description) as description,
    card_member,
    accountx,
    amount::decimal(18, 2) as cost,
    trim(extended_details) as notes,
    trim(appears_on_your_statement_as) as appears_on_your_statement_as,
    trim(address) as address_lines,
    trim(town_city) as city,
    trim(postcode) as postcode,
    trim(country) as country,
    trim(category) as category,

    _dlt_id,
    _dlt_load_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.american_express.american_express_statements
;
