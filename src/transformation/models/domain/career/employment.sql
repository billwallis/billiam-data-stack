model (
    name warehouse.career.employment,
    kind full,
    grain (start_date),
    tags (daily-tracker),
    columns (
        start_date date,
        end_date date,
        company varchar,
        team varchar,
    ),
    audits (
        not_null(columns=[
            start_date,
            end_date,
            company,
            team,
        ]),
        unique_values(columns=[
            start_date,
            end_date,
        ]),
    ),
);

select
    start_date,
    end_date,
    company,
    team,
from ods.daily_tracker.employment
;
