-- shaperid:y6c1lcqk7g98zadea0dhz2m4
-- shapersync:2026-08-13T05:50:56Z

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

select ''::SECTION;

select 'Private repos'::LABEL;
select url
from warehouse.coding.github_repositories
where 1=1
    and is_own_repo
    and visibility = 'PRIVATE'
    and not is_archived
order by url
;

select 'Incorrect settings'::LABEL;
-- assert__repository_settings_are_correct
with my_active_repos as (
    select
        url,
        /* return True if the repo should be flagged as "misconfigured" */
        nullif(description, '') is null as description_is_null,
        not ends_with(description, '.') as incorrect_description_terminator,
        licence_id is null as not_has_license,
        (not is_private and not auto_merge_allowed) as auto_merge_not_allowed,
        not delete_branch_on_merge as delete_branch_on_merge_not_allowed,
        not forking_allowed as forking_not_allowed,
        has_discussions_enabled,
        not has_issues_enabled as issues_not_enabled,
        has_projects_enabled,
        not has_vulnerability_alerts_enabled as vulnerability_alerts_not_enabled,
        has_wiki_enabled,
        not rebase_merge_allowed as rebase_merge_not_allowed,
        not merge_commit_allowed as merge_commit_not_allowed,
        -- merge_commit_title != '...' as incorrect_merge_commit_title,
        -- merge_commit_message != '...' as incorrect_merge_commit_message,
        not squash_merge_allowed as squash_merge_not_allowed,
        -- squash_merge_title != '...' as incorrect_squash_merge_title,
        -- squash_merge_message != '...' as incorrect_squash_merge_message,
        (not is_private and not plan_features__codeowners) as codeowners_not_enabled,
        not plan_features__draft_pull_requests as draft_pull_requests_not_enabled,
        web_commit_signoff_required,
        is_disabled,
        is_empty,
        is_locked,
    from warehouse.coding.github_repositories
    where 1=1
        and username = owner_username  /* my own repos */
        and not is_archived
)

from (
    unpivot my_active_repos
    on columns(* exclude (url))
    into
        name setting
        value is_misconfigured
)
select
    url,
    list(setting order by setting) filter (where is_misconfigured) as issues,
group by url
having issues is not null
order by url
;
