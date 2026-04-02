model (
    name warehouse.raw_ods.amex_transactions,
    kind full,
    grain (transaction_id),
    tags (finances),
    allow_partials true,
    columns (
        transaction_id varchar,
        transaction_date date,
        description varchar,
        cost decimal(18, 2),
        notes varchar,
        appears_on_statement_as varchar,
        address_lines varchar,
        city varchar,
        postcode varchar,
        country varchar,
        category varchar,
    ),
    audits (
        not_null(columns=[
            transaction_date,
        ]),
        -- unique_values(columns=[
        --     transaction_date,
        -- ]),
    ),
);


select
    trim("Reference") as transaction_id,

    "Date"::date as transaction_date,
    trim("Description") as description,
    "Amount"::decimal(18, 2) as cost,
    trim("Extended Details") as notes,
    trim("Appears On Your Statement As") as appears_on_statement_as,
    trim("Address") as address_lines,
    trim("Town/City") as city,
    trim("Postcode") as postcode,
    trim("Country") as country,
    trim("Category") as category,
from ods.finances.amex_transactions
;

/*
    Amex transactions can be downloaded from the Amex website at:

    - https://global.americanexpress.com/activity/statements
*/
