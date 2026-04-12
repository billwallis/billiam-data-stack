model (
    name warehouse.raw_notion.databases,
    kind full,
    grain (database_id),
    tags (notion),
    columns (
        database_id uuid,
        block_id uuid,
        object_type varchar,
        title varchar,
        description varchar,
        is_inline boolean,
        is_trashed boolean,
        is_locked boolean,
        url varchar,
        request_id uuid,
        created_at timestamp,
        updated_at timestamp,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            database_id,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            database_id,
            _dlt_id,
        ]),
    ),
);


select
    id as database_id,
    parent->>'$.block_id' as block_id,
    object as object_type,
    titles.title,
    descriptions.description,
    is_inline,
    in_trash as is_trashed,
    is_locked,
    url,
    request_id,
    created_time as created_at,
    last_edited_time as updated_at,
    _dlt_load_id,
    _dlt_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.notion.databases
    cross join lateral (
        from (
            select unnest(title->>'$[*].plain_text') as title_parts
            from landing.notion.databases as i
            where databases.id = i.id
        )
        select string_agg(title_parts, '')
    ) as titles(title)
    cross join lateral (
        from (
            select unnest(description->>'$[*].plain_text') as description_parts
            from landing.notion.databases as i
            where databases.id = i.id
        )
        select string_agg(description_parts, '')
    ) as descriptions(description)
;
