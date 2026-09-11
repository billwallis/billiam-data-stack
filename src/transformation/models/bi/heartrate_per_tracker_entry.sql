model (
    name warehouse.bi.heartrate_per_tracker_entry,
    kind full,
    enabled false,
    grain (start_time),
    columns (
        start_time timestamp,
        end_time timestamp,
        project varchar,
        detail varchar,
        log_ts timestamp,
        bpm integer,
    ),
    audits (
        not_null(columns=[
            start_time,
            end_time,
            project,
            detail,
            log_ts,
            bpm,
        ]),
        unique_values(columns=[
            log_ts,
        ]),
    ),
);


with tasks as (
    select
        log_ts as start_time,
        log_ts + to_minutes(minutes) as end_time,
        project,
        detail,
    from warehouse.career.daily_tracker
    where project != 'Lunch Break'
)

select
    tasks.start_time,
    tasks.end_time,
    tasks.project,
    tasks.detail,
    heartrate.log_ts,
    heartrate.bpm,
from tasks
    inner join warehouse.health.heartrate
        on  heartrate.log_ts >= tasks.start_time
        and heartrate.log_ts <  tasks.end_time
;
