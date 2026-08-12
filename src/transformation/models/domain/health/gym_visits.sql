model (
    name warehouse.health.gym_visits,
    kind full,
    grain (visit_id),
    tags (pure_gym),
    columns (
        visit_id integer,
        start_time timestamp,
        end_time timestamp,
        duration_minutes integer,
        gym_id integer,
    ),
    audits (
        not_null(columns=[
            visit_id,
            start_time,
            end_time,
            duration_minutes,
            gym_id,
        ]),
        unique_values(columns=[
            visit_id,
            start_time,
            end_time,
        ]),
    ),
);


select
    visit_id,
    start_time,
    start_time + to_minutes(duration) as end_time,
    duration as duration_minutes,
    gym__id as gym_id,
from warehouse.raw_pure_gym.gym_sessions__visits
order by visit_id
;
