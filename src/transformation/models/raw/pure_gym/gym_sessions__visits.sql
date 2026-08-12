model (
    name warehouse.raw_pure_gym.gym_sessions__visits,
    kind full,
    grain (visit_id),
    tags (pure_gym),
    columns (
        visit_id integer,
        start_time timestamp,
        duration integer,
        is_duration_estimated boolean,
        gym__id integer,
        gym__name varchar,
        gym__status varchar,
        gym__location varchar,
        gym__gym_access varchar,
        gym__contact_info varchar,
        gym__time_zone varchar,
        _dlt_id varchar,
        _dlt_parent_id varchar,
        _dlt_list_idx integer,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            visit_id,
            _dlt_id,
            _dlt_parent_id,
            _dlt_list_idx,
            _load_ts,
        ]),
        unique_values(columns=[
            visit_id,
            _dlt_id,
        ]),
    ),
);


select
    epoch(start_time::timestamp) as visit_id,
    start_time,
    duration,
    is_duration_estimated,
    gym->>'$.Id' as gym__id,
    gym->>'$.Name' as gym__name,
    gym->>'$.Status' as gym__status,
    gym->>'$.Location' as gym__location,
    gym->>'$.GymAccess' as gym__gym_access,
    gym->>'$.ContactInfo' as gym__contact_info,
    gym->>'$.TimeZone' as gym__time_zone,
    _dlt_id,
    _dlt_parent_id,
    _dlt_list_idx,
    (
        select @dlt_load_ts(gym_sessions._dlt_load_id)
        from landing.pure_gym.gym_sessions
        where gym_sessions__visits._dlt_parent_id = gym_sessions._dlt_id
    ) as _load_ts,
from landing.pure_gym.gym_sessions__visits
qualify _load_ts = max(_load_ts) over (partition by visit_id)
order by visit_id
;
