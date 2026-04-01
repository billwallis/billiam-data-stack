model (
    name warehouse.raw_ods.counterparty_exclusions,
    kind full,
    grain (counterparty),
    tags (finances),
    columns (
      counterparty varchar,
    ),
);

select counterparty
from ods.finances.counterparty_exclusions
;
