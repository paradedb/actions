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
      approvers: pg_search-maintainers
      slack_alert_mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
    secrets:
      SLACK_WEBHOOK_URL: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
      PARADEDB_GITHUB_APP_PRIVATE_KEY: ${{ secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY }}
```

For manual promotion, call `.github/workflows/upstream-sync-promote.yml@v10`.

Prefer an org team slug for `approvers` over a list of usernames. Both are
accepted, but a hardcoded list silently drifts from the team it mirrors as
people join and leave, and nothing surfaces the drift.

## CI gate

The rebase polls for check runs against the `target-patch-*` commit it pushes
and **fails on a 100-minute timeout if it finds none** — validation cannot be
skipped. The target repo therefore needs at least one workflow that triggers on
`push` to `target-patch-*`:

```yaml
on:
  push:
    branches: [main, "target-patch-*"]
```

Prefer adding the branch to an existing CI workflow's trigger over introducing a
new workflow file, so the fork carries a smaller conflict surface on rebase.
Check that the gate can actually pass on the fork: a workflow inherited from
upstream may depend on constraints the fork has deliberately dropped, in which
case it will never go green and the sync will never promote.

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
- optional Slack webhook secret mapped to `SLACK_WEBHOOK_URL`
