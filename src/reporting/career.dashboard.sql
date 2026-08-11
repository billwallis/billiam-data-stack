-- shaperid:lwl2v5kh7d2cn27kk4s8f8qc
-- shapersync:2026-08-11T21:47:18Z

select 'Career'::SECTION;

select max(log_ts)::date as "Latest tracker entry"
from warehouse.career.daily_tracker
;
select round(sum(hours) / 8.0, 2) as "AL days taken or booked"  /* TODO: Divide using `working_hours` model */
from warehouse.career.work_absences
where 1=1
    and absence_date >= date_trunc('year', current_date)
    and absence_reason = 'Annual leave'
;
select min(date_nk) as "Next bank holiday"
from warehouse.calendar.bank_holidays
where date_nk >= current_date
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Operational stuff and things'::SECTION;

select 'Days not accounted for'::LABEL;
select date_nk
from warehouse.ops.tracker_days_not_accounted_for
where date_nk <= (
    select max(log_ts)::date
    from warehouse.career.daily_tracker
)
order by date_nk
;

select 'Bradford factor'::LABEL;
select
    instance_id,
    sick_days,
    instance_count,
    total_sick_days,
    bradford_factor,
from warehouse.ops.bradford_factor
order by instance_id
;
