-- shaperid:e14s593sm0tclv7i858onii5
-- shapersync:2026-09-11T08:37:12Z

select 'Tasman wrap-up'::SECTION;

set variable tasman_start_date = (
    select min(start_date)
    from warehouse.career.employment
    where company = 'Tasman'
);
set variable tasman_end_date = (
    select max(end_date)
    from warehouse.career.employment
    where company = 'Tasman'
);

select getvariable('tasman_end_date') - getvariable('tasman_start_date') as "Days of employment"
;
select count(*) as "Days in the office"
from warehouse.finances.transaction_items
where item = 'Tube ...'  -- Replace with the real commute
;
select sum(hours_worked) as "Total hours worked"
from warehouse.bi.career_daily_log
where date_nk >= getvariable('tasman_start_date')
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Quiz questions'::SECTION;

create or replace temporary table tasman_heartrate_per_tracker_entry as
    from warehouse.bi.heartrate_per_tracker_entry
    where log_ts::date between getvariable('tasman_start_date')
                           and getvariable('tasman_end_date')
    order by log_ts
;

select 'BPM per meeting'::LABEL;
select
    detail as meeting_name,
    avg(bpm)::numeric(12, 4) as avg_bpm,
    median(bpm) as median_bpm,
from tasman_heartrate_per_tracker_entry
where project = 'Meetings'
group by meeting_name
-- having bpm_logs >= 10
order by median_bpm desc
limit 5
;

select 'BPM per story'::LABEL;
select
    project as story_name,
    avg(bpm)::numeric(12, 4) as avg_bpm,
    median(bpm) as median_bpm,
from tasman_heartrate_per_tracker_entry
group by story_name
-- having bpm_logs >= 10
order by avg_bpm desc
limit 5
;


select ''::SECTION;

select 'CXP, time, and BPM per client'::LABEL;
with

tracker as (
    select
        project as story_name,
        detail as task_name,
        sum(minutes) as minutes,
    from warehouse.career.daily_tracker
    where 1=1
        and log_ts::date >= getvariable('tasman_start_date')
        and project not in (
            -- Default tasks
            'Adhoc Task',
            'Adhoc Chat',
            'Documentation',
            'Housekeeping',
            'Lunch Break',
            'Peer Review',
            'Personal Development',
            'Unable to Work',
            -- Additional stuff
            'Onboarding',
            'Away Day',
        )
    group by all
),

joined as (
    select
        story_name,
        task_name,
        if(
            tracker.story_name = 'Meetings',
            tracker.story_name,
            tasman_monday_tasks.client_name
        ) as client_name,
        tasman_monday_tasks.cxp,
        tasman_monday_tasks.is_done,
        coalesce(tracker.minutes, 0) as minutes,
        heartrates.sum_bpm,
        heartrates.count_bpm,
    from tracker
        full join '...path/to/extract.csv' as tasman_monday_tasks
            using (story_name, task_name)
        left join (
            select
                project as story_name,
                detail as task_name,
                sum(bpm) as sum_bpm,
                count(*) as count_bpm,
            from tasman_heartrate_per_tracker_entry
            group by story_name, task_name
        ) as heartrates
            using (story_name, task_name)
)

select
    client_name,
    sum(if(is_done, cxp, 0)) as total_cxp,
    sum(minutes) as total_minutes,
    format_minutes(total_minutes) as total_time,
    (total_minutes / nullif(total_cxp, 0))::decimal(6, 2) as minutes_per_cxp,
    (sum(sum_bpm) / sum(count_bpm))::decimal(6, 2) as avg_bpm,
from joined
group by client_name
order by all
;


select ''::SECTION;

select 'Total meeting proportion'::LABEL;
select
    sum(minutes) as total_minutes,
    sum(minutes) filter (where project = 'Meetings') as meeting_minutes,
    format_minutes(total_minutes) as total_time,
    format_minutes(meeting_minutes) as meeting_time,
    (100 * meeting_minutes / total_minutes)::decimal(8, 4) as meeting_proportion,
from warehouse.career.daily_tracker
where 1=1
    and project != 'Lunch Break'
    and log_ts::date >= getvariable('tasman_start_date')
;


select ''::SECTION;

select 'Adhoc chats'::LABEL;
with

tasmanites(pattern, colleague_name) as (
    values
        -- Replace with real names
        ('\bAlex\b', 'Alex'),
        ('\bBlake\b', 'Blake'),
        ('\bCharlie\b', 'Charlie'),
),

tracker as (
    select
        daily_tracker.log_ts,
        daily_tracker.detail,
        daily_tracker.minutes,
        tasmanites.colleague_name,
    from warehouse.career.daily_tracker
        inner join tasmanites
            on regexp_matches(daily_tracker.detail, tasmanites.pattern)
    where 1=1
        and daily_tracker.project = 'Adhoc Chat'
        and daily_tracker.log_ts::date between getvariable('tasman_start_date')
                                           and getvariable('tasman_end_date')
)

select
    colleague_name,
    sum(minutes) as total_minutes,
    format_minutes(total_minutes) as total_time
from tracker
group by colleague_name
order by total_minutes desc
;


select ''::SECTION;

select 'Hours worked and overtime'::LABEL;
select
    sum(hours_worked) as hours_worked,
    sum(expected_hours) as expected_hours,
    sum(extra_hours) as extra_hours,
    countif(is_working_day) as working_days,
    (sum(extra_hours) / countif(is_working_day))::decimal(12, 2) as extra_hours_per_day,
from warehouse.bi.career_daily_log
where date_nk >= getvariable('tasman_start_date')
;
