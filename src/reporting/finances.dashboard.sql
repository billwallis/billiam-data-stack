-- shaperid:gj3macp27jf7ol0kzueeao5z
-- shapersync:2026-08-13T12:03:46Z

select 'Finances'::SECTION;

select max(transaction_date) as "Latest transaction date"
from warehouse.finances.transactions
;
select count(*) as "Transactions this year"
from warehouse.finances.transactions
where transaction_date >= date_trunc('year', current_date)
;
select sum(cost) as "Total net amount"
from warehouse.finances.transactions
where transaction_date >= date_trunc('year', current_date)
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Monthly transactions'::SECTION;

select 'Transaction value by month'::LABEL;
with

axis(transaction_month) as (
    select date_nk
    from warehouse.calendar.calendar
    where 1=1
        and year_number = year(current_date)
        and is_month_start
),

transactions as (
    select
        date_trunc('month', transaction_date) as transaction_month,
        sum(cost) as total_net_amount,
    from warehouse.finances.transactions
    where transaction_date >= date_trunc('year', current_date)
    group by transaction_month
)

select
    transaction_month::XAXIS,
    coalesce(transactions.total_net_amount)::BARCHART_STACKED,
    if(transactions.total_net_amount < 0, 'good', 'bad')::CATEGORY,  /* Can we have better names? :laugh: */
    if(transactions.total_net_amount < 0, '#00ff00', '#ff0000')::COLOR,
from axis
    left join transactions
        using (transaction_month)
order by transaction_month
;

select ''::SECTION;

select 'Transaction value by month and category'::LABEL;
with

transactions as (
    select
        date_trunc('month', transaction_date) as transaction_month,
        category,
        sum(cost) as total_net_amount,
    from warehouse.finances.transaction_items
    where transaction_date >= date_trunc('year', current_date)
    group by transaction_month, category
),

_months(transaction_month) as (
    select date_nk
    from warehouse.calendar.calendar
    where 1=1
        and year_number = year(current_date)
        and is_month_start
),
axis as (
    select transaction_month, category
    from _months
        cross join (
            select distinct category
            from transactions
        ) as categories
)

select
    transaction_month::XAXIS,
    category::CATEGORY,
    coalesce(transactions.total_net_amount, 0)::BARCHART_STACKED,
from axis
    left join transactions
        using (transaction_month, category)
order by transaction_month, category
;

select 'Categories'::SECTION;

select 'This year''s transactions by category'::LABEL;
select
    category,
    count(distinct transaction_id) as transactions,
    sum(cost) as total_amount_net,
    sum(if(cost > 0, cost, 0)) as total_amount_out,
    sum(if(cost < 0, cost, 0)) as total_amount_in,
from warehouse.finances.transaction_items
where transaction_date >= date_trunc('year', current_date)
group by rollup (category)
order by grouping_id(category), total_amount_net desc
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Retailers'::SECTION;

select 'Top retailers this year (by count)'::LABEL;
select
    counterparty,
    count(*) as total_transations,
    sum(cost) as total_net_amount,
from warehouse.finances.transactions
where transaction_date >= date_trunc('year', current_date)
group by counterparty
order by total_transations desc
limit 5
;
select 'Top retailers this year (by value)'::LABEL;
select
    counterparty,
    count(*) as total_transations,
    sum(cost) as total_net_amount,
from warehouse.finances.transactions
where transaction_date >= date_trunc('year', current_date)
group by counterparty
order by total_net_amount desc
limit 5
;
