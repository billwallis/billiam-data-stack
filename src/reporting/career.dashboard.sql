-- shaperid:lwl2v5kh7d2cn27kk4s8f8qc
-- shapersync:2026-08-13T07:50:54Z

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
where 1=1
    and date_nk >= current_date
    and region = 'england-and-wales'
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Time spent per employer (all time)'::SECTION;

create or replace temporary table company_branding as
    -- https://pickxcolor.com/en
    from (
        values
            ('TSB',          '#0f7cc1'),
            ('Jaja',         '#282828'),
            ('Allica',       '#ff5100'),
            ('Sainsbury''s', '#f47320'),
            ('Tasman',       '#90b39d'),
    ) as v(company, brand_colour)
;

select 'Hours in meetings per month per employer'::LABEL;
with metrics as (
    select
        date_trunc('month', daily_metrics.metric_date) as metric_month,
        work_hours.company,
        any_value(company_branding.brand_colour) as brand_colour,
        sum(daily_metrics.meeting_time) / 60 as total_meeting_hours,
    from warehouse.bi.daily_metrics
        inner join warehouse.career.work_hours
            on daily_metrics.metric_date between work_hours.from_date
                                             and work_hours.to_date
        left join company_branding
            using (company)
    where daily_metrics.metric_date >= '2019-05-01'  -- First month with full data
    group by metric_month, company
)

select
    metric_month::XAXIS,
    company::CATEGORY,
    brand_colour::COLOR,
    total_meeting_hours::BARCHART_STACKED,
from metrics
order by metric_month, company
;

select ''::SECTION;

select 'Hours worked per month per employer'::LABEL;
with metrics as (
    select
        date_trunc('month', daily_metrics.metric_date) as metric_month,
        work_hours.company,
        any_value(company_branding.brand_colour) as brand_colour,
        sum(daily_metrics.total_working_time) / 60 as total_working_hours,
    from warehouse.bi.daily_metrics
        inner join warehouse.career.work_hours
            on daily_metrics.metric_date between work_hours.from_date
                                             and work_hours.to_date
        left join company_branding
            using (company)
    where daily_metrics.metric_date >= '2019-05-01'  -- First month with full data
    group by metric_month, company
)

select
    metric_month::XAXIS,
    company::CATEGORY,
    brand_colour::COLOR,
    total_working_hours::BARCHART_STACKED,
from metrics
order by metric_month, company
;

select ''::SECTION;

select 'Meeting proportion per month per employer'::LABEL;
with metrics as (
    select
        date_trunc('month', daily_metrics.metric_date) as metric_month,
        work_hours.company,
        any_value(company_branding.brand_colour) as brand_colour,
        sum(daily_metrics.meeting_time) / 60 as total_meeting_hours,
        sum(daily_metrics.total_working_time) / 60 as total_working_hours,
        total_meeting_hours / total_working_hours as meeting_time_proportion,
    from warehouse.bi.daily_metrics
        inner join warehouse.career.work_hours
            on daily_metrics.metric_date between work_hours.from_date
                                             and work_hours.to_date
        left join company_branding
            using (company)
    where daily_metrics.metric_date >= '2019-05-01'  -- First month with full data
    group by metric_month, company
)

select
    metric_month::XAXIS,
    company::CATEGORY,
    brand_colour::COLOR,
    meeting_time_proportion::LINECHART,
from metrics
order by metric_month, company
;

select 'Calendar'::SECTION;

select 'Daily work hours (ideally this would be a heatmap, like GitHub contributions)'::LABEL;
with

axis as (
    select
        date_nk,
        day_name,
        -- `week_number` expects Monday to be start of week
        if(day_of_week_number = 0, 7, day_of_week_number) as day_of_week_number,
        week_number,
    from warehouse.calendar.calendar
    -- where year_number = year(current_date)
    where (year_number, month_number) = (year(current_date), month(current_date))
),

metrics as (
    select
        date_nk,
        concat(axis.day_of_week_number, ' ', axis.day_name) as day_of_week,
        format('{:02d}', axis.week_number) as week_number,
        coalesce(daily_metrics.total_working_time, 0) /60 as total_working_hours,
    from axis
        left join warehouse.bi.daily_metrics
            on axis.date_nk = daily_metrics.metric_date
)

pivot metrics
on week_number
using any_value(total_working_hours)
group by day_of_week
order by day_of_week
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
