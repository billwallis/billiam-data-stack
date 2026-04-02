model (
    name warehouse.finances.transaction_items,
    kind full,
    grain (row_id),
    allow_partials true,
    columns (
        row_id int,
        transaction_date date,
        transaction_id int,
        item varchar,
        cost decimal(18, 2),
        category varchar,
        counterparty varchar,
        exclusion_flag bool,
    ),
);


select
    finances.row_id,
    finances.transaction_date,
    finances.transaction_id,
    finances.item,
    finances.cost,
    finances.category,
    finances.counterparty,
    finances.exclusion_flag,
from warehouse.raw_google_sheets.finances
    semi join warehouse.finances.transactions
        using (transaction_id)
order by finances.row_id
