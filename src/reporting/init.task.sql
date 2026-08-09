-- shaperid:xff6j1mijobfrfs50ibbre7h
-- shapersync:2026-08-10T15:14:04Z

select 'init'::SCHEDULE;

detach database if exists warehouse;
attach 'md:warehouse' as warehouse;
