-- shaperid:u4zqqvqef1ch6ns03dg1mr8v
-- shapersync:2026-09-11T07:50:23Z

select 'init'::SCHEDULE;

create or replace macro format_minutes(time_in_minutes) as
    format(
        '{:d} hours, {:d} minutes',
        floor(time_in_minutes // 60)::int,
        floor(time_in_minutes % 60)::int
    )
;
