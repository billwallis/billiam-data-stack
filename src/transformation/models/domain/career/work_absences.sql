model (
    name warehouse.career.work_absences,
    kind full,
    grain (absence_date),
    tags (daily-tracker),
    columns (
        absence_date date,
        absence_reason varchar,
        hours decimal(4, 2),
    ),
    audits (
        not_null(columns=[
            absence_date,
            absence_reason,
            hours,
        ]),
        unique_values(columns=[
            absence_date,
        ]),
    ),
);

select
    absence_date,

    absence_reason,
    hours,
from warehouse.raw_ods.work_absences
;
