model (
    name warehouse.ops.benfords_law,
    kind full,
    grain (n),
    columns (
        n integer,
        row_digit_count integer,
        transaction_digit_count integer,
        cost_digit_count integer,
        rounded_cost_digit_count integer,
        row_digit_proportion decimal(7, 4),
        transaction_digit_proportion decimal(7, 4),
        cost_digit_proportion decimal(7, 4),
        rounded_cost_digit_proportion decimal(7, 4),
    ),
    audits (
        not_null(columns=[
            n,
            row_digit_count,
            transaction_digit_count,
            cost_digit_count,
            rounded_cost_digit_count,
            row_digit_proportion,
            transaction_digit_proportion,
            cost_digit_proportion,
            rounded_cost_digit_proportion,
        ]),
        unique_values(columns=[
            n,
        ]),
    ),
);


with

axis as (
    select n
    /* Purposefully exclude 0 */
    from generate_series(1, 9, 1) as gs(n)
),

digits as (
    select
        left(row_id::text, 1) as row_digit,
        left(transaction_id::text, 1) as transaction_digit,
        left(abs(cost)::text, 1) as cost_digit,
        left(abs(round(cost))::text, 1) as rounded_cost_digit,
    from warehouse.raw_google_sheets.finances
),

counts as (
    select
        n,
        (select count(*) from digits where axis.n = digits.row_digit) as row_digit_count,
        (select count(*) from digits where axis.n = digits.transaction_digit) as transaction_digit_count,
        (select count(*) from digits where axis.n = digits.cost_digit) as cost_digit_count,
        (select count(*) from digits where axis.n = digits.rounded_cost_digit) as rounded_cost_digit_count,
    from axis
)

select
    n,
    row_digit_count,
    transaction_digit_count,
    cost_digit_count,
    rounded_cost_digit_count,
    row_digit_count / sum(row_digit_count) over () as row_digit_proportion,
    transaction_digit_count / sum(transaction_digit_count) over () as transaction_digit_proportion,
    cost_digit_count / sum(cost_digit_count) over () as cost_digit_proportion,
    rounded_cost_digit_count / sum(rounded_cost_digit_count) over () as rounded_cost_digit_proportion,
from counts
;
