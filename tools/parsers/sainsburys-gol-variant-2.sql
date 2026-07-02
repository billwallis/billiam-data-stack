/*
    This variant is for where the items are on their own line:

        4 Super Noodles Chicken Flavour 90g £3.80
        3 Sainsbury's Aubergine £2.85
        ...
*/
/**/
select version();


/* Read in the file */
create or replace temporary view receipt as
    select column0 as line
    from read_csv(
        'tools/parsers/data/sainsburys-gol-variant-2.csv',
        header=false,
        sep=''
    )
;


/* GOL Items */
with

data as (
    from (
        from receipt
        select
            row_number() over () as line_id,
            split(line, ' ') as parts,
            (
                list_aggregate(parts[2:-2], 'string_agg', ' ')
                .replace('Sainsbury''s ', '')
                .replace('Habitat ', '')
            ) as item_name,
            (parts[-1]).replace('£', '')::decimal(8, 2) as line_price,
            parts[1]::int as quantity,
    )
    select
        line_id,
        item_name,
        quantity,
        line_price,
        (line_price / quantity)::decimal(8, 2) as price,
),

uplift(quantity) as (
    select i.i
    from (select max(quantity) as n from data)
        cross join generate_series(1, n) as i(i)
        inner join generate_series(1, n) as j(j)
            on i.i >= j.j
),

lines as (
        select
            line_id,
            item_name,
            price,
            'Food' as category,
        from data
            natural inner join uplift
    union all
        values
            (98, 'Delivery', null, 'Administration'),
)

select
    item_name,
    price,
    category,
    'Sainsbury''s' as primary_retailer,
    '' as secondary_retailer,
    'Amex' as payment_method,
    -- '<Split>' as payment_method,
    0 as exclusion_flag,
from lines
order by line_id
;
