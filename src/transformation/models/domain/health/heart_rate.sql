model (
    name warehouse.health.heartrate,
    kind full,
    grain (log_ts),
    tags (oura),
    columns (
        log_ts timestamp,

        bpm integer,
        producer_timestamp bigint,
        source varchar,
    ),
    audits (
        not_null(columns=[
            log_ts,
        ]),
        unique_values(columns=[
            log_ts,
        ]),
    ),
);


select
    timezone('Europe/London', "timestamp") as log_ts,

    bpm,
    producer_timestamp,
    source,
from warehouse.raw_oura.heartrate
/* Where there are overlapping local timestamps (from DST), take the latest */
qualify 1 = row_number() over (
    partition by log_ts
    order by "timestamp" desc
)
;
