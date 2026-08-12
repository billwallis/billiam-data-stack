-- shaperid:cjgduxms6ra6uv7ny2mr77go
-- shapersync:2026-08-12T21:03:12Z

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
        from warehouse.health.gym_visits
        where 1=1
            and start_time <  (current_date - interval '1 month')::timestamp
            and start_time >= date_trunc('month', current_date)::timestamp - interval '1 month'
    )::COMPARE as "Gym visits this time last month",
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
from warehouse.health.heart_rate
where log_ts > date_trunc('month', current_date)::timestamp
group by log_hour
order by log_hour
;
