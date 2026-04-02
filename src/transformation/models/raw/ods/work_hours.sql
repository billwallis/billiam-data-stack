model (
    name warehouse.raw_ods.work_hours,
    kind full,
    grain (company, from_date),
    tags (daily-tracker),
    allow_partials true,
    columns (
      company varchar,
      from_date date,
      to_date date,
      sunday decimal(4, 2),
      monday decimal(4, 2),
      tuesday decimal(4, 2),
      wednesday decimal(4, 2),
      thursday decimal(4, 2),
      friday decimal(4, 2),
      saturday decimal(4, 2),
    ),
    audits (
        not_null(columns=[
            company,
            from_date,
            to_date,
            sunday,
            monday,
            tuesday,
            wednesday,
            thursday,
            friday,
            saturday,
        ]),
    ),
);

select
    company,
    from_date,
    to_date,

    sunday,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
from ods.daily_tracker.work_hours
;
