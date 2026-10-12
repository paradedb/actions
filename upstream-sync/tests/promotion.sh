#!/bin/bash
set -euo pipefail

export UPSTREAM_REPO=example/upstream UPSTREAM_REPO_URL=https://github.com/example/upstream
export TARGET_REPO=example/target TARGET_REMOTE=origin UPSTREAM_REMOTE=upstream
# shellcheck source=upstream-sync/scripts/sync-core.sh
source "$(dirname "$0")/../scripts/sync-core.sh"

branch=target-patch-2026-10-12-161429
sha=validated-commit
pushes=0
fetch_branch() { :; }
git() {
  case "$1" in
    rev-parse) echo "$sha" ;;
    push) pushes=$((pushes + 1)) ;;
    tag) : ;;
    *)
      echo "Unexpected git command: $*" >&2
      return 1
      ;;
  esac
}
sleep() {
  echo 'Unexpected sleep' >&2
  return 1
}
gh() {
  case "$scenario" in
    unauthorized)
      echo 'gh: Bad credentials (HTTP 401)' >&2
      return 1
      ;;
    malformed) echo '{"message":"Bad credentials"}' ;;
    success) echo '{"check_runs":[{"name":"Tests","status":"completed","conclusion":"success"}]}' ;;
    annotation-error)
      if [[ "$2" == *check-runs*annotations ]]; then
        return 1
      fi
      echo '{"check_runs":[{"id":1,"app":{"slug":"github-actions"},"name":"Tests","status":"completed","conclusion":"failure","html_url":"https://github.com/example/target/actions/runs/1/job/2"}]}'
      ;;
  esac
}

for scenario in unauthorized malformed annotation-error; do
  if poll_ci_status "$branch"; then
    echo "Expected validation failure for $scenario" >&2
    exit 1
  fi
done
scenario=success
poll_ci_status "$branch"
complete_promotion "$branch" "$sha"
[[ "$pushes" -eq 3 ]]

pushes=0
if complete_promotion "$branch" different-commit; then
  echo 'Expected changed branch to fail' >&2
  exit 1
fi
[[ "$pushes" -eq 0 ]]

echo 'Promotion regression tests passed'
