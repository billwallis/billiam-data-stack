model (
    name warehouse.raw_ods.work_absences,
    kind full,
    grain (absence_date),
    tags (daily-tracker),
    columns (
      absence_date date,
      absence_reason varchar,
      hours decimal(4, 2),
    ),
);

select
    absence_date,
    absence_reason,
    hours,
from ods.daily_tracker.work_absences
;
