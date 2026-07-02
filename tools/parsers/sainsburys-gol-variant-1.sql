/*
    This variant is for where the items are split into three lines:

        4
        Super Noodles Chicken Flavour 90g
        £3.80
        3
        Sainsbury's Aubergine
        £2.85
        ...
*/
/**/
select version();


/* Read in the file */
create or replace temporary view receipt as
    select column0 as line
    from read_csv(
        'tools/parsers/data/sainsburys-gol-variant-1.csv',
        header=false,
        sep=''
    )
;
/* DQ check */
from receipt
select case when (count(*) / 3) % 1 != 0 then error('some lines are missing') end
;


/* GOL Items */
with

data as (
    from (
        from receipt
        select line, -1 + row_number() over () as row_id,
    )
    select
        line,
        row_id % 3 as part_id,
        sum((part_id = 0)::int) over (order by row_id rows unbounded preceding) as item_id,
),

prices as (
    from (
        select
            item_id,
            item.line.replace('Sainsbury''s ', '') as item_name,
            quantity.line::int as quantity,
            line_price.line.replace('£', '')::decimal(8, 2) as line_price,
        from data as item
            inner join data as quantity
                using (item_id)
            inner join data as line_price
                using (item_id)
        where 1=1
            and item.part_id = 1
            and quantity.part_id = 0
            and line_price.part_id = 2
    )
    select
        item_id,
        item_name,
        quantity,
        line_price,
        (line_price / quantity)::decimal(8, 2) as price,
),

uplift(quantity) as (
    select i.i
    from (select max(quantity) as n from prices)
        cross join generate_series(1, n) as i(i)
        inner join generate_series(1, n) as j(j)
            on i.i >= j.j
),

lines as (
        select
            item_id,
            item_name,
            price,
            'Food' as category
        from prices
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
order by item_id
;
