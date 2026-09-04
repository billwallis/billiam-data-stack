model (
    name warehouse.bi.career_daily_log,
    kind full,
    grain (date_nk),
    columns (
        date_nk date,
        day_name text,
        is_working_day boolean,
        contracted_hours decimal(12, 2),
        absent_hours decimal(12, 2),
        hours_worked decimal(12, 2),
        expected_hours decimal(12, 2),
        extra_hours decimal(12, 2),
    ),
    audits (
        not_null(columns=[
            date_nk,
            day_name,
            is_working_day,
            contracted_hours,
            absent_hours,
            hours_worked,
            expected_hours,
            extra_hours,
        ]),
        unique_values(columns=[
            date_nk,
        ]),
    ),
);


with

_contracted_hours as (
    from (
        unpivot warehouse.career.work_hours
        on monday, tuesday, wednesday, thursday, friday, saturday, sunday
        into
            name day_name
            value contracted_hours
    )
    select
        from_date,
        to_date,
        company,
        day_name,
        contracted_hours,
),
contracted_hours as (
    select
        calendar.date_nk,
        calendar.day_name,
        coalesce(_contracted_hours.contracted_hours, 0) as contracted_hours,
    from warehouse.calendar.calendar
        left join _contracted_hours
            on calendar.date_nk between _contracted_hours.from_date
                                    and _contracted_hours.to_date
            and calendar.day_name = _contracted_hours.day_name collate nocase
    where calendar.date_nk between '2018-01-01'::date and current_date
),

absent_hours as (
    select
        absence_date as date_nk,
        hours as absent_hours,
        absence_reason,
    from warehouse.career.work_absences
),

hours_worked as (
    select
        metric_date as date_nk,
        (total_working_time / 60)::decimal(14, 2) as hours_worked,
    from warehouse.bi.daily_metrics
),

comparison as (
    select
        date_nk,
        contracted_hours.day_name,

        contracted_hours.contracted_hours,
        coalesce(absent_hours.absence_reason, '') as absence_reason,
        coalesce(absent_hours.absent_hours, 0) as absent_hours,
        coalesce(hours_worked.hours_worked, 0) as hours_worked,
        (0
            + coalesce(contracted_hours.contracted_hours, 0)
            - coalesce(absent_hours.absent_hours, 0)
        ) as expected_hours,
        (1=1
            and coalesce(contracted_hours.contracted_hours, 0) > 0
            and coalesce(absent_hours.absent_hours, 0) = 0  /* TODO: what about half-days? */
        ) as is_working_day,
        hours_worked.hours_worked - expected_hours as extra_hours,
    from contracted_hours
        left join absent_hours
            using (date_nk)
        left join hours_worked
            using (date_nk)
)

select
    date_nk,
    day_name,
    is_working_day,
    contracted_hours,
    absent_hours,
    hours_worked,
    expected_hours,
    extra_hours,
from comparison
order by date_nk
;
