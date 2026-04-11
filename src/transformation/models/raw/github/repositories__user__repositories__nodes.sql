model (
    name warehouse.raw_github.repositories__user__repositories__nodes,
    kind full,
    grain (repository_id),
    tags (github),
    allow_partials true,
    audits (
        not_null(columns=[
            repository_id,
            _dlt_id,
            _dlt_list_idx,
            _dlt_parent_id,
        ]),
        unique_values(columns=[
            repository_id,
            _dlt_id,
        ]),
        assert__all_github_repos_are_pulled,
    ),
);


select
    id as repository_id,

    archived_at,
    auto_merge_allowed,
    created_at,
    database_id,
    delete_branch_on_merge,
    description,
    disk_usage,
    fork_count,
    forking_allowed,
    has_discussions_enabled,
    has_issues_enabled,
    has_projects_enabled,
    has_sponsorships_enabled,
    has_vulnerability_alerts_enabled,
    has_wiki_enabled,
    homepage_url,
    is_archived,
    is_blank_issues_enabled,
    is_disabled,
    is_empty,
    is_fork,
    is_in_organization,
    is_locked,
    is_mirror,
    is_private,
    is_security_policy_enabled,
    is_template,
    is_user_configuration_repository,
    latest_release__id,
    latest_release__name,
    latest_release__published_at,
    latest_release__tag_name,
    latest_release__url,
    license_info__id,
    license_info__key,
    license_info__name,
    license_info__nickname,
    license_info__description,
    license_info__body,
    license_info__url,
    merge_commit_allowed,
    merge_commit_message,
    merge_commit_title,
    name,
    name_with_owner,
    open_graph_image_url,
    owner__login,
    plan_features__codeowners,
    plan_features__draft_pull_requests,
    plan_features__maximum_assignees,
    plan_features__maximum_manual_review_requests,
    plan_features__team_review_requests,
    primary_language__color,
    primary_language__id,
    primary_language__name,
    pushed_at,
    rebase_merge_allowed,
    resource_path,
    squash_merge_allowed,
    squash_merge_commit_message,
    squash_merge_commit_title,
    stargazer_count,
    updated_at,
    url,
    uses_custom_open_graph_image,
    visibility,
    web_commit_signoff_required,

    _dlt_id,
    _dlt_list_idx,
    _dlt_parent_id,
from landing.github_user.repositories__user__repositories__nodes
;


------------------------------------------------------------------------
------------------------------------------------------------------------

audit (name assert__all_github_repos_are_pulled);
with

expected as (
    select
        repositories_total_count,
        _dlt_id,
        _load_ts,
    from warehouse.raw_github.repositories
    qualify _dlt_load_id = max(_dlt_load_id) over ()
),

actual as (
    select count(*) as repositories_total_count
    from warehouse.raw_github.repositories__user__repositories__nodes as repos
        inner join expected
            on expected._dlt_id = repos._dlt_parent_id
)

select
    (select any_value(repositories_total_count) from expected) as expected,
    (select repositories_total_count from actual) as actual,
where expected != actual
;
