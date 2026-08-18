-- shaperid:mbtr57vbjtoi9nmiqpgxecgs
-- shapersync:2026-08-18T10:36:48Z

select 'This month so far'::SECTION;

with

hours_worked(hours_worked) as (
    select sum(daily_metrics.total_working_time) / 60
    from warehouse.bi.daily_metrics
    where metric_date between date_trunc('month', current_date)
                          and current_date - interval '1 day'
),

absent_hours(absent_hours) as (
    select sum(hours)
    from warehouse.career.work_absences
    where absence_date between date_trunc('month', current_date)
                           and current_date - interval '1 day'
),

_contracted_hours as (
    unpivot warehouse.career.work_hours
    on monday, tuesday, wednesday, thursday, friday, saturday, sunday
    into
        name day_name
        value contracted_hours
),
contracted_hours(contracted_hours) as (
    select sum(_contracted_hours.contracted_hours)
    from warehouse.calendar.calendar
        inner join _contracted_hours
            on calendar.date_nk between _contracted_hours.from_date
                                    and _contracted_hours.to_date
            and calendar.day_name = _contracted_hours.day_name collate nocase
    where calendar.date_nk between date_trunc('month', current_date)
                               and current_date - interval '1 day'
)

select
    hours_worked.hours_worked as "Hours worked",
    (0
        + contracted_hours.contracted_hours
        - absent_hours.absent_hours
    )::COMPARE as "Expected hours",
from hours_worked, contracted_hours, absent_hours
;
select sum(cost) as "Money spent"
from warehouse.finances.transactions
where transaction_date >= date_trunc('month', current_date)
;
select
    (
        select count(*)
        from warehouse.health.gym_visits
        where start_time >= date_trunc('month', current_date)::timestamp
    ) as "Gym visits",
    (
        select count(*)
        from warehouse.calendar.calendar
        where 1=1
            and date_nk < current_date
            and (year_number, month_number) = (year(current_date), month(current_date))
            -- Currently committed to going on these days
            and day_name in ('Sunday', 'Wednesday')
    )::COMPARE as "Planned visits",
;
