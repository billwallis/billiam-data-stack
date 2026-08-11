-- shaperid:gj3macp27jf7ol0kzueeao5z
-- shapersync:2026-08-10T18:36:23Z

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
