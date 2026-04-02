model (
    name warehouse.raw_github.repositories,
    kind full,
    grain (user_id, _dlt_id),
    tags (github),
    columns (
        user_id varchar,
        login varchar,
        repositories_total_count int,
        _page_info__end_cursor varchar,
        _page_info__start_cursor varchar,
        _page_info__has_previous_page boolean,
        _page_info__has_next_page boolean,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            user_id,
            login,
            repositories_total_count,
            _page_info__end_cursor,
            _page_info__start_cursor,
            _page_info__has_previous_page,
            _page_info__has_next_page,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[_dlt_id]),
    ),
);


select
    user__id as user_id,

    user__login as login,
    user__repositories__total_count as repositories_total_count,

    user__repositories__page_info__end_cursor as _page_info__end_cursor,
    user__repositories__page_info__start_cursor as _page_info__start_cursor,
    user__repositories__page_info__has_previous_page as _page_info__has_previous_page,
    user__repositories__page_info__has_next_page as _page_info__has_next_page,

    _dlt_id,
    _dlt_load_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.github_user.repositories
;
