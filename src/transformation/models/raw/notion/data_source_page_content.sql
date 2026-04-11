model (
    name warehouse.raw_notion.data_source_page_content,
    kind full,
    grain (block_id),
    tags (notion),
    columns (
        block_id uuid,
        page_id uuid,
        object_type varchar,
        has_children boolean,
        is_trashed boolean,
        block_type varchar,
        heading_3 json,
        paragraph json,
        divider json,
        callout json,
        created_at timestamp,
        updated_at timestamp,
        _dlt_id varchar,
        _dlt_load_id varchar,
        _load_ts timestamp,
    ),
    audits (
        not_null(columns=[
            block_id,
            _dlt_id,
            _dlt_load_id,
            _load_ts,
        ]),
        unique_values(columns=[
            block_id,
            _dlt_id,
        ]),
    ),
);


select
    id as block_id,
    parent->>'$.page_id' as page_id,
    object as object_type,
    has_children,
    in_trash as is_trashed,
    "type" as block_type,
    heading_3,
    paragraph,
    divider,
    callout,
    created_time as created_at,
    last_edited_time as updated_at,
    _dlt_load_id,
    _dlt_id,
    make_timestamp(1000000 * _dlt_load_id::bigint) as _load_ts,
from landing.notion.data_source_page_content
order by page_id
;
