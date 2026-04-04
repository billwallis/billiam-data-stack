model (
    name warehouse.calendar.bank_holidays,
    kind full,
    grain (date_nk),
    columns (
        date_nk date,
        region varchar,
        title varchar,
        notes varchar,
    ),
);


select
    date_nk,
    region,
    title,
    notes,
from 'https://raw.githubusercontent.com/billwallis/dbt-calendar/refs/tags/v0.0.1/seeds/bank_holidays.csv'
;
