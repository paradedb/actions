# Upstream Sync

Composite actions for keeping a target repository rebased on an upstream repository.

## Files

- `upstream-sync-rebase/action.yml`: rebase and automatic promotion action.
- `upstream-sync-promote/action.yml`: manual promotion action for resolved patch branches.
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

The actions require an Ubuntu runner with Git, GitHub CLI, jq, and curl (all
available on `ubuntu-latest`). They generate the app token and check out the
caller repository themselves. Keep triggers and concurrency in the caller.

These examples use `v13`, which must be released with the composite actions
before migrating callers. Existing `v12` reusable-workflow callers continue to
use the files at that tag.

Add a rebase caller workflow:

```yaml
permissions:
  actions: write
  checks: read
  contents: write
  issues: write
  pull-requests: read

jobs:
  upstream-rebase:
    runs-on: ubuntu-latest
    steps:
      - name: Upstream Rebase
        uses: paradedb/actions/upstream-sync-rebase@v13
        with:
          github_app_client_id: ${{ vars.PARADEDB_GITHUB_APP_CLIENT_ID }}
          github_app_private_key: ${{ secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY }}
          approvers: pg_search-maintainers
          slack_alert_mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
          slack_webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
          username_mapping_github_to_slack: ${{ vars.USERNAME_MAPPING_GITHUB_TO_SLACK }}
```

For manual promotion:

```yaml
on:
  workflow_dispatch:
    inputs:
      branch_name:
        description: Resolved target-patch-* branch to promote
        required: true
        type: string

permissions:
  actions: write
  contents: write
  issues: write
  pull-requests: read

jobs:
  promote-branch:
    runs-on: ubuntu-latest
    steps:
      - name: Promote Target Patch Branch
        uses: paradedb/actions/upstream-sync-promote@v13
        with:
          branch_name: ${{ inputs.branch_name }}
          github_app_client_id: ${{ vars.PARADEDB_GITHUB_APP_CLIENT_ID }}
          github_app_private_key: ${{ secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY }}
          approvers: pg_search-maintainers
          slack_webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
          username_mapping_github_to_slack: ${{ vars.USERNAME_MAPPING_GITHUB_TO_SLACK }}
```

Prefer an org team slug for `approvers` over a list of usernames. Both are
accepted, but a hardcoded list silently drifts from the team it mirrors as
people join and leave, and nothing surfaces the drift.

## Failure alerts

Who gets paged depends on whether the failure can be pinned on a commit.

- **Rebase conflict.** One upstream commit is at fault, so its author is paged
  when they appear in `vars.USERNAME_MAPPING_GITHUB_TO_SLACK`. An outside
  contributor will not, so `slack_alert_mention` is paged instead.
- **CI validation failure, or any other error.** The rebase applied cleanly, so
  no single commit is at fault and `slack_alert_mention` is paged. `github.actor`
  is not used, because on a `schedule` run it resolves to whoever last edited the
  workflow file.

`approvers` is a promotion roster, not an alert routing list. It is paged only
when no `slack_alert_mention` is set, and `<!here>` when neither is configured.

Required repository config:

- `vars.PARADEDB_GITHUB_APP_CLIENT_ID`
- `secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY`
- optional `vars.USERNAME_MAPPING_GITHUB_TO_SLACK`
- optional Slack webhook secret passed as `slack_webhook_url`
