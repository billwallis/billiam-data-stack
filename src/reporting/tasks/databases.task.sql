-- shaperid:xff6j1mijobfrfs50ibbre7h
-- shapersync:2026-09-11T08:37:12Z

select 'init'::SCHEDULE;

detach database if exists warehouse;
attach 'md:warehouse' as warehouse;
