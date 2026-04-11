model (
    name warehouse.coding.github_repositories,
    kind full,
    grain (repository_id),
    tags (github),
    allow_partials true,
    audits (
        not_null(columns=[
            repository_id,
            user_id,
            username,
            name_with_owner,
            visibility,
            url,
            owner_username,
            name,
            is_template,
            _load_ts,
        ]),
        unique_values(columns=[
            repository_id,
            name_with_owner,
            url,
        ]),
        assert__repository_settings_are_correct,
    ),
);

with latest as (
    select
        user_id,
        login,
        repositories_total_count,
        _dlt_id,
        _load_ts,
    from warehouse.raw_github.repositories
    qualify _dlt_load_id = max(_dlt_load_id) over (partition by user_id)
)


select
    repositories.repository_id,
    latest.user_id,
    latest.login as username,

    repositories.name_with_owner,
    repositories.description,
    repositories.visibility,
    repositories.url,
    repositories.owner__login as owner_username,

    /*    Licence    */
    license_info__id as licence_id,
    license_info__key as licence_key,
    license_info__name as licence_name,
    license_info__nickname as licence_nickname,

    /*    General Settings    */
    /* General */
    repositories.name,
    repositories.is_template,
    /* Default branch */
    -- nothing yet, should be default branch name
    /* Releases */
    -- nothing yet, should have "Enable release immutability" bool
    /* Social preview */
    repositories.uses_custom_open_graph_image,
    repositories.open_graph_image_url,
    /* Features */
    repositories.has_wiki_enabled,
    repositories.has_issues_enabled,
    repositories.has_sponsorships_enabled,
    -- "Preserve this repository" bool
    repositories.has_discussions_enabled,
    repositories.has_projects_enabled,
    -- "Pull requests" bool
    -- "Pull request permissions" enum
    /* Pull Requests */
    repositories.merge_commit_allowed,
    repositories.merge_commit_title,
    repositories.merge_commit_message,
    repositories.squash_merge_allowed,
    repositories.squash_merge_commit_title,
    repositories.squash_merge_commit_message,
    repositories.rebase_merge_allowed,
    -- "Always suggest updating pull request branches" bool
    repositories.auto_merge_allowed,
    repositories.delete_branch_on_merge,
    /* Commits */
    repositories.web_commit_signoff_required,
    -- "Allow comments on individual commits" bool
    /* Archives */
    -- "Include Git LFS objects in archives" bool
    /* Pushes */
    -- "Limit how many branches and tags can be updated in a single push" bool

    /*    Security and quality    */
    /* Overview */
    repositories.is_security_policy_enabled,
    -- "Security advisories" bool
    repositories.has_vulnerability_alerts_enabled,
    -- "Dependabot alerts" bool
    -- "Code scanning alerts" bool
    -- "Secret scanning alerts" bool

    /*    Flags    */
    repositories.forking_allowed,
    repositories.is_archived,
    repositories.is_blank_issues_enabled,
    repositories.is_disabled,
    repositories.is_empty,
    repositories.is_fork,
    repositories.is_in_organization,
    repositories.is_locked,
    repositories.is_mirror,
    repositories.is_private,
    repositories.is_user_configuration_repository,

    /*    Properties    */
    repositories.database_id,
    repositories.created_at,
    repositories.updated_at,
    repositories.pushed_at,
    repositories.archived_at,
    repositories.homepage_url,
    repositories.resource_path,
    repositories.disk_usage,
    repositories.fork_count,
    repositories.stargazer_count,
    repositories.primary_language__color,
    repositories.primary_language__id,
    repositories.primary_language__name,
    repositories.latest_release__id,
    repositories.latest_release__name,
    repositories.latest_release__published_at,
    repositories.latest_release__tag_name,
    repositories.latest_release__url,
    repositories.plan_features__codeowners,
    repositories.plan_features__draft_pull_requests,
    repositories.plan_features__maximum_assignees,
    repositories.plan_features__maximum_manual_review_requests,
    repositories.plan_features__team_review_requests,

    latest._load_ts,
from latest
    left join warehouse.raw_github.repositories__user__repositories__nodes as repositories
        on latest._dlt_id = repositories._dlt_parent_id
;


------------------------------------------------------------------------
------------------------------------------------------------------------

audit (
    name assert__repository_settings_are_correct,
    blocking false,
);
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
