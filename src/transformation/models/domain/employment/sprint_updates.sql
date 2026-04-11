model (
    name warehouse.career.sprint_updates,
    kind full,
    grain (page_id),
    columns (
        page_id uuid,
        title varchar,
        start_date date,
        end_date date,
        sentiment varchar,
        love varchar[],
        loathe varchar[],
        sprint_demo_items varchar[],
        company varchar,
        team varchar,
        is_locked boolean,
        url varchar,
        created_at timestamp,
        updated_at timestamp,
    ),
    audits (
        not_null(columns=[
            page_id,
            title,
            start_date,
            end_date,
            company,
            created_at,
            updated_at,
        ]),
        unique_values(columns=[
            page_id,
        ]),
    ),
);


select
    page_id,
    _sprint.title,
    (properties->>'$.Date.date.start')::date as start_date,
    (properties->>'$.Date.date.end')::date as end_date,
    properties->>'$.Sentiment.select.name' as sentiment,
    list_transform(
        split(_love.love, e'\n'),
        lambda x: ltrim(x, ' -*•')
    ) as love,
    list_transform(
        split(_loathe.loathe, e'\n'),
        lambda x: ltrim(x, ' -*•')
    ) as loathe,
    list_transform(
        split(_sprint_demo_items.sprint_demo_items, e'\n'),
        lambda x: ltrim(x, ' -*•')
    ) as sprint_demo_items,
    properties->>'$.Company.select.name' as company,
    properties->>'$.Team.select.name' as team,
    is_locked,
    url,
    created_at,
    updated_at,
from warehouse.raw_notion.data_source_pages
    cross join lateral (
        from (
            select unnest(properties->>'$.Sprint.title[*].plain_text') as parts
            from warehouse.raw_notion.data_source_pages as i
            where data_source_pages.page_id = i.page_id
        )
        select string_agg(parts, '')
    ) as _sprint(title)
    cross join lateral (
        from (
            select unnest(properties->>'$.Love.rich_text[*].plain_text') as parts
            from warehouse.raw_notion.data_source_pages as i
            where data_source_pages.page_id = i.page_id
        )
        select string_agg(parts, '')
    ) as _love(love)
    cross join lateral (
        from (
            select unnest(properties->>'$.Loathe.rich_text[*].plain_text') as parts
            from warehouse.raw_notion.data_source_pages as i
            where data_source_pages.page_id = i.page_id
        )
        select string_agg(parts, '')
    ) as _loathe(loathe)
    cross join lateral (
        from (
            select unnest(properties->>'$.Sprint Demo Items.rich_text[*].plain_text') as parts
            from warehouse.raw_notion.data_source_pages as i
            where data_source_pages.page_id = i.page_id
        )
        select string_agg(parts, '')
    ) as _sprint_demo_items(sprint_demo_items)
where 1=1
    and object_type = 'page'
    and not is_trashed
    and not is_archived
    and exists(
        from warehouse.raw_notion.data_sources
        where data_source_pages.data_source_id = data_sources.data_source_id
          and data_sources.title = 'Daily Updates'
    )
order by start_date
;
