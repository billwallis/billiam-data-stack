-- shaperid:y6c1lcqk7g98zadea0dhz2m4
-- shapersync:2026-08-11T10:53:44Z

select 'Coding'::SECTION;

select count(*) as "Total personal repositories"
from warehouse.coding.github_repositories
where is_own_repo
;
select count(*) as "Repos with feature branches"
from warehouse.coding.github_repositories
where 1=1
    and is_own_repo
    and branches_count > 1
;
select sum(open_pull_request_count) as "Open pull requests"
from warehouse.coding.github_repositories
where is_own_repo
;


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

select 'Quick links'::SECTION;

select 'Multiple branches'::LABEL;
select
    branches_count as branches,
    url,
from warehouse.coding.github_repositories
where 1=1
    and is_own_repo
    and branches_count > 1
order by branches desc, url
;

select 'Open pull requests'::LABEL;
select
    open_pull_request_count as open_prs,
    concat(url, '/pulls') as pull_requests_url,
from warehouse.coding.github_repositories
where 1=1
    and is_own_repo
    and open_pull_request_count != 0
order by open_prs desc, url
;
