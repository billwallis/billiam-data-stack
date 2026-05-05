model (
    name warehouse.raw_pure_gym.gym_sessions__summary,
    kind full,
    grain (_load_ts),
    tags (pure_gym),
    columns (
        summary__total__activities integer,
        summary__total__visits integer,
        summary__total__duration integer,
        summary__this_week__activities integer,
        summary__this_week__visits integer,
        summary__this_week__duration integer,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            summary__total__activities,
            summary__total__visits,
            summary__total__duration,
            summary__this_week__activities,
            summary__this_week__visits,
            summary__this_week__duration,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            _dlt_id,
            _load_ts,
        ]),
    ),
);


select
    summary__total->>'$.Activities' as summary__total__activities,
    summary__total->>'$.Visits' as summary__total__visits,
    summary__total->>'$.Duration' as summary__total__duration,
    summary__this_week->>'$.Activities' as summary__this_week__activities,
    summary__this_week->>'$.Visits' as summary__this_week__visits,
    summary__this_week->>'$.Duration' as summary__this_week__duration,
    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.pure_gym.gym_sessions
order by _load_ts
;
