model (
    name warehouse.raw.github__repositories,
    kind full,
    grain (user_id, _dlt_id),
    tags (github),
);


select
    user__id as user_id,
    user__login,
    user__repositories__total_count,

    user__repositories__page_info__end_cursor,
    user__repositories__page_info__start_cursor,
    user__repositories__page_info__has_previous_page,
    user__repositories__page_info__has_next_page,

    _dlt_id,
    _dlt_load_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.github_user.repositories
;
