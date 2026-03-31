model (
    name warehouse.career.weekly_working_hours,
    kind full,
    grain (week_starting),
    columns (
        week_starting date,
        weekly_quota decimal(6, 4),
        absence_hours decimal(6, 4),
        expected_working_hours decimal(6, 4),
    ),
    audits (
      not_null(columns=[
        week_starting,
        weekly_quota,
        absence_hours,
        expected_working_hours,
      ]),
      unique_values(columns=[week_starting]),
    ),
);


with

weeks as (
    select date_nk as week_starting
    from warehouse.calendar.calendar
    where 1=1
        and date_nk = date_trunc('week', date_nk)  /* is_week_start */
        and date_nk <= current_date
        and date_nk >= (
            select date_trunc('week', min(from_date))
            from warehouse.raw__dev.work_hours
        )
),

weekly_quota as (
    select
        from_date,
        coalesce(to_date, '9999-12-31') as to_date,
        (0
            + sunday
            + monday
            + tuesday
            + wednesday
            + thursday
            + friday
            + saturday
        ) as weekly_quota
    from warehouse.raw.work_hours
),

absence_hours as (
    select
        date_trunc('week', absence_date) as week_starting,
        sum(hours) as absence_hours
    from warehouse.raw.work_absences
    group by all
),

all_hours as (
    select
        weeks.week_starting,
        coalesce(weekly_quota.weekly_quota, 0) as weekly_quota,
        coalesce(absence_hours.absence_hours, 0) as absence_hours
    from weeks
        left join weekly_quota
            on weeks.week_starting between weekly_quota.from_date and weekly_quota.to_date
        left join absence_hours
            using (week_starting)
)

select
    week_starting,
    weekly_quota,
    absence_hours,
    weekly_quota - absence_hours as expected_working_hours
from all_hours
order by week_starting
;
