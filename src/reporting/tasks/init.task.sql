-- shaperid:xff6j1mijobfrfs50ibbre7h
-- shapersync:2026-08-16T08:44:08Z

select 'init'::SCHEDULE;

detach database if exists warehouse;
attach 'md:warehouse' as warehouse;
