model (
    name warehouse.raw_notion.data_source_pages,
    kind full,
    grain (page_id),
    tags (notion),
    columns (
        page_id uuid,
        data_source_id uuid,
        database_id uuid,
        object_type varchar,
        properties json,
        is_trashed boolean,
        is_archived boolean,
        is_locked boolean,
        url varchar,
        created_at timestamp,
        updated_at timestamp,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            page_id,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            page_id,
            _dlt_id,
        ]),
    ),
);


select
    id as page_id,
    parent->>'$.data_source_id' as data_source_id,
    parent->>'$.database_id' as database_id,
    object as object_type,
    properties,
    in_trash as is_trashed,
    is_archived,
    is_locked,
    url,
    created_time as created_at,
    last_edited_time as updated_at,
    _dlt_load_id,
    _dlt_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.notion.data_source_pages
