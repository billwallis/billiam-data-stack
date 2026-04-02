model (
    name warehouse.raw_ods.counterparty_exclusions,
    kind full,
    grain (counterparty),
    tags (finances),
    allow_partials true,
    columns (
        counterparty varchar,
    ),
    audits (
        not_null(columns=[
            counterparty,
        ]),
        unique_values(columns=[
            counterparty,
        ]),
    ),
);

select counterparty
from ods.finances.counterparty_exclusions
;
