model (
    name warehouse.health.daily_biometrics,
    kind full,
    grain (date_nk),
    tags (oura),
    columns (
        date_nk date,

        activity_score integer,
        readiness_score integer,
        sleep_score integer,
        steps integer,
        resilience_level text,
        stress_level text,
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
    where date_nk between '2025-09-02'  /* This is when I got the ring */
                      and current_date
),

activity as (
    select
        "day" as date_nk,
        score as activity_score,
        steps,
    from warehouse.raw_oura.daily_activity
),

readiness as (
    select
        "day" as date_nk,
        score as readiness_score,
    from warehouse.raw_oura.daily_readiness
),

resilience as (
    select
        "day" as date_nk,
        "level" as resilience_level,
    from warehouse.raw_oura.daily_resilience
),

sleep as (
    select
        "day" as date_nk,
        score as sleep_score,
    from warehouse.raw_oura.daily_sleep
),

stress as (
    select
        "day" as date_nk,
        day_summary as stress_level,
    from warehouse.raw_oura.daily_stress
)

select
    date_nk,
    activity.activity_score,
    readiness.readiness_score,
    sleep.sleep_score,

    activity.steps,
    resilience.resilience_level,
    stress.stress_level,
from axis
    left join activity
        using (date_nk)
    left join readiness
        using (date_nk)
    left join resilience
        using (date_nk)
    left join sleep
        using (date_nk)
    left join stress
        using (date_nk)
order by date_nk
;
