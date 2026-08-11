model (
    name warehouse.ops.bradford_factor,
    kind full,
    grain (instance_id),
    columns (
        instance_id int,
        sick_days int,
        instance_count int,
        total_sick_days int,
        bradford_factor int,
    ),
    audits (
        not_null(columns=[
            instance_id,
        ]),
        unique_values(columns=[
            instance_id,
        ]),
    ),
);

/*
    Bradford Factor (B)

        B = S^2 * D

    ...where:

    - S is the total number of separate absences
    - D is the total number of days of absence

    ---

    https://www.bradfordfactorcalculator.com/

    ---

    If two sick days are separated by a non-working absence (weekend,
    non-working day, AL), do they count as separate instances?

    For the below, we will assume "no" -- any string of absences is a
    single instance.
*/
with

calendar as (
    select date_nk, is_day_weekday
    from warehouse.calendar.calendar
    where date_nk between current_date - 365 and current_date
),

calendar_absences as (
    select
        calendar.date_nk,
        coalesce(
            work_absences.absence_reason,
            if(calendar.is_day_weekday, null, 'Weekend')
        ) as day_type,
        (1=1
            and day_type is not null
            and lag(day_type) over (order by calendar.date_nk) is null
        )::int as instance_start
    from calendar
        left join warehouse.career.work_absences
            on calendar.date_nk = work_absences.absence_date
),

instance_flags as (
    select
        date_nk,
        day_type,
        instance_start,
        sum(instance_start) over (order by date_nk) as instance_id,
        day_type = 'Sick day' as is_sick_day
    from calendar_absences
    order by date_nk
),

sick_instances as (
    select
        instance_id,
        count_if(is_sick_day) as sick_days
    from instance_flags
    group by instance_id
    having sick_days > 0
)

select
    instance_id,
    sick_days,

    count(distinct instance_id) over () as instance_count,
    sum(sick_days) over () as total_sick_days,
    (instance_count ^ 2) * total_sick_days as bradford_factor,
from sick_instances
order by instance_id
;
