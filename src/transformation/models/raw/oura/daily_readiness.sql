model (
    name warehouse.raw_oura.daily_readiness,
    kind full,
    grain (id),
    tags (oura),
    columns (
        id varchar,
        day date,
        timestamp timestamptz,

        score integer,
        temperature_deviation decimal(5, 2),
        temperature_trend_deviation decimal(5, 2),

        contributors__activity_balance integer,
        contributors__body_temperature integer,
        contributors__hrv_balance integer,
        contributors__previous_day_activity integer,
        contributors__previous_night integer,
        contributors__recovery_index integer,
        contributors__resting_heartrate integer,
        contributors__sleep_balance integer,
        contributors__sleep_regularity integer,

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            id,
            day,
            timestamp,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            id,
            day,
            timestamp,
            _dlt_id,
        ]),
    ),
);


select
    id,
    "day",
    "timestamp",

    score,
    temperature_deviation,
    temperature_trend_deviation,

    -- contributors,
    contributors->>'$.activity_balance' as contributors__activity_balance,
    contributors->>'$.body_temperature' as contributors__body_temperature,
    contributors->>'$.hrv_balance' as contributors__hrv_balance,
    contributors->>'$.previous_day_activity' as contributors__previous_day_activity,
    contributors->>'$.previous_night' as contributors__previous_night,
    contributors->>'$.recovery_index' as contributors__recovery_index,
    contributors->>'$.resting_heart_rate' as contributors__resting_heartrate,
    contributors->>'$.sleep_balance' as contributors__sleep_balance,
    contributors->>'$.sleep_regularity' as contributors__sleep_regularity,

    _dlt_id,
    _dlt_load_id,
    @dlt_load_ts(_dlt_load_id) as _load_ts,
from landing.oura.daily_readiness
;
