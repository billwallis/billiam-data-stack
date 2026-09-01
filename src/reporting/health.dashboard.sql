-- shaperid:cjgduxms6ra6uv7ny2mr77go
-- shapersync:2026-08-21T08:06:44Z

select 'Health'::SECTION;

select max(start_time) as "Last gym visit"
from warehouse.health.gym_visits
;
select
    (
        select count(*)
        from warehouse.health.gym_visits
        where start_time >= date_trunc('month', current_date)::timestamp
    ) as "Gym visits this month",
    (
        select count(*)
        from warehouse.calendar.calendar
        where 1=1
            and date_nk < current_date
            and (year_number, month_number) = (year(current_date), month(current_date))
            -- Currently committed to going on these days
            and day_name in ('Sunday', 'Wednesday')
    )::COMPARE as "Planned gym visits",
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Biometrics'::SECTION;

select 'Hourly average heart rate'::LABEL;
select
    date_trunc('hour', log_ts)::XAXIS as log_hour,
    min(bpm)::BAND_LOWER,
    avg(bpm)::LINECHART,
    max(bpm)::BAND_UPPER,
from warehouse.health.heartrate
where log_ts >= date_trunc('month', current_date)::timestamp
group by log_hour
order by log_hour
;

select ''::SECTION;

select 'Daily average heart rate'::LABEL;
select
    (log_ts::date)::XAXIS as date_nk,
    min(bpm)::BAND_LOWER,
    avg(bpm)::LINECHART,
    max(bpm)::BAND_UPPER,
from warehouse.health.heartrate
where log_ts >= date_trunc('month', current_date)::timestamp
group by date_nk
order by date_nk
;

select ''::SECTION;

select 'Daily scores'::LABEL;
with daily_scores as (
    select
        date_nk,
        activity_score as activity,
        readiness_score as readiness,
        sleep_score as sleep,
    from warehouse.health.daily_biometrics
    where date_nk >= date_trunc('month', current_date)
)

from (
    unpivot daily_scores
    on activity, readiness, sleep
    into name metric_name value metric_value
)
select
    date_nk::XAXIS,
    metric_name::CATEGORY,
    metric_value::LINECHART,
order by date_nk
;

select ''::SECTION;

select 'Daily stress and resilience'::LABEL;
with daily_scores as (
    select
        date_nk,
        case resilience_level
            when 'adequate'    then 1
            when 'solid'       then 2
            when 'strong'      then 3
            when 'exceptional' then 4
        end as resilience,
        case stress_level
            when 'stressful' then 1
            when 'normal'    then 2
            when 'restored'  then 3
        end as stress,
    from warehouse.health.daily_biometrics
    where date_nk >= date_trunc('month', current_date)
)

from (
    unpivot daily_scores
    on resilience, stress
    into name metric_name value metric_value
)
select
    date_nk::XAXIS,
    metric_name::CATEGORY,
    (case metric_name
        when 'resilience' then '#00ff00'
        when 'stress'     then '#ff0000'
    end)::COLOR,
    metric_value::LINECHART,
order by date_nk
;
