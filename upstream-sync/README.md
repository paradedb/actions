# Upstream Sync

Reusable workflows for keeping a target repository rebased on an upstream repository.

## Files

- `.github/workflows/upstream-sync-rebase.yml`: scheduled rebase workflow.
- `.github/workflows/upstream-sync-promote.yml`: manual promotion workflow for resolved patch branches.
- `upstream-sync/scripts/sync-core.sh`: shared implementation.
- `upstream-sync/scripts/sync-upstream.sh`: wrapper template to copy into target repos as `scripts/sync-upstream.sh`.

## Setup

Copy `upstream-sync/scripts/sync-upstream.sh` into the target repo and set:

```bash
export UPSTREAM_REPO="paradedb/paradedb"
export UPSTREAM_REPO_URL="https://github.com/paradedb/paradedb.git"
export TARGET_REPO="paradedb/paradedb-enterprise"
export TARGET_BRANCH="main"
export UPSTREAM_BRANCH="main"
```

Add a caller workflow:

```yaml
jobs:
  upstream-rebase:
    uses: paradedb/actions/.github/workflows/upstream-sync-rebase.yml@v10
    with:
      github_app_client_id: ${{ vars.PARADEDB_GITHUB_APP_CLIENT_ID }}
      approvers: "philippemnoel,rebasedming,stuhood,mdashti"
      slack_alert_mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
    secrets:
      SLACK_WEBHOOK_URL: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
      PARADEDB_GITHUB_APP_PRIVATE_KEY: ${{ secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY }}
```

For manual promotion, call `.github/workflows/upstream-sync-promote.yml@v10`.

## Failure alerts

Who gets paged depends on whether the failure can be pinned on a commit:

- **Rebase conflict** — exactly one upstream commit is at fault. Its author is
  paged when they appear in `vars.USERNAME_MAPPING_GITHUB_TO_SLACK`; otherwise
  they are an outside contributor and `slack_alert_mention` is paged.
- **CI validation failure, or any other error** — the rebase applied cleanly, so
  the failure spans the whole batch of rebased commits with no single author to
  blame. `slack_alert_mention` is paged. Note that `github.actor` is not used
  here: on a `schedule` run it resolves to whoever last edited the workflow file.

`approvers` is a promotion-approval roster, not an alert routing list. It is only
paged as a fallback for repositories that set no `slack_alert_mention`, and
`<!here>` is the last resort when neither is configured.

Required repository config:

- `vars.PARADEDB_GITHUB_APP_CLIENT_ID`
- `secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY`
- optional `vars.USERNAME_MAPPING_GITHUB_TO_SLACK`
- optional Slack webhook secret mapped to `SLACK_WEBHOOK_URL`
