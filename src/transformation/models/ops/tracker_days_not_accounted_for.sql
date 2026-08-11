model (
    name warehouse.ops.tracker_days_not_accounted_for,
    kind full,
    grain (date_nk),
    columns (
        date_nk date,
    ),
    audits (
        not_null(columns=[
            date_nk,
        ]),
        unique_values(columns=[
            date_nk,
        ]),
    ),
);

with

axis as (
    select date_nk
    from warehouse.calendar.calendar
    where 1=1
        -- and date_nk between '2019-04-23'::date and current_date
        and date_nk between '2022-01-01'::date and current_date
        and is_day_weekday
),

bank_holidays as (
    select date_nk
    from warehouse.calendar.bank_holidays
),

worked_days(date_nk) as (
    select log_ts::date
    from warehouse.career.daily_tracker
),

absence_days(date_nk) as (
    select absence_date
    from warehouse.career.work_absences
)

select axis.date_nk
from axis
    anti join bank_holidays
        using (date_nk)
    anti join worked_days
        using (date_nk)
    anti join absence_days
        using (date_nk)
    semi join warehouse.career.employment
        on axis.date_nk between employment.start_date
                            and employment.end_date
order by date_nk
;
