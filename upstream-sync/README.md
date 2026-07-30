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

Required repository config:

- `vars.PARADEDB_GITHUB_APP_CLIENT_ID`
- `secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY`
- optional `vars.USERNAME_MAPPING_GITHUB_TO_SLACK`
- optional Slack webhook secret mapped to `SLACK_WEBHOOK_URL`
