model (
    enabled false,
    name warehouse.raw_oura.rest_mode_period,
    kind full,
    grain (id, episodes__timestamp),
    tags (oura),
    columns (
        id varchar,

        start_day date,
        end_day date,
        end_time timestamptz,
        start_time timestamptz,

        episodes__timestamp timestamptz,
        episodes__tags varchar[],

        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            id,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            id,
            _dlt_id,
        ]),
    ),
);


from (
    select
        id,
        start_day,
        end_day,
        start_time,
        end_time,
        unnest(episodes::json[]) as episodes,
        _dlt_id,
        _dlt_load_id,
        @dlt_load_ts(_dlt_load_id) as _load_ts,
    from landing.oura.rest_mode_period
)
select
    id,

    start_day,
    end_day,
    start_time,
    end_time,
    episodes->>'$.timestamp' as episodes__timestamp,
    episodes->>'$.tags' as episodes__tags,

    _dlt_id,
    _dlt_load_id,
    _load_ts,
;
