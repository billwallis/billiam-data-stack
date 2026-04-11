model (
    name warehouse.raw_notion.data_sources,
    kind full,
    grain (data_source_id),
    tags (notion),
    columns (
        data_source_id uuid,
        database_id uuid,
        block_id uuid,
        object_type varchar,
        title varchar,
        description varchar,
        properties json,
        is_inline boolean,
        is_trashed boolean,
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
            data_source_id,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            data_source_id,
            _dlt_id,
        ]),
    ),
);


select
    id as data_source_id,
    parent->>'$.database_id' as database_id,
    database_parent->>'$.block_id' as block_id,
    object as object_type,
    titles.title,
    descriptions.description,
    properties,
    is_inline,
    in_trash as is_trashed,
    url,
    request_id,
    created_time as created_at,
    last_edited_time as updated_at,
    _dlt_load_id,
    _dlt_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.notion.data_sources
    cross join lateral (
        from (
            select unnest(title->>'$[*].plain_text') as title_parts
            from landing.notion.data_sources as i
            where data_sources.id = i.id
        )
        select string_agg(title_parts, '')
    ) as titles(title)
    cross join lateral (
        from (
            select unnest(description->>'$[*].plain_text') as description_parts
            from landing.notion.data_sources as i
            where data_sources.id = i.id
        )
        select string_agg(description_parts, '')
    ) as descriptions(description)
;
