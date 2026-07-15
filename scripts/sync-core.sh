#!/bin/bash

# Unified upstream rebase script - consolidated batch processing
# This script handles all upstream rebase operations in a single unified flow

set -Eeuo pipefail

# --- Parameterization ---
: "${UPSTREAM_REPO:?UPSTREAM_REPO must be set (e.g., paradedb/paradedb)}"
: "${UPSTREAM_REPO_URL:?UPSTREAM_REPO_URL must be set (e.g., https://github.com/paradedb/paradedb.git)}"
: "${TARGET_REPO:?TARGET_REPO must be set (e.g., paradedb/paradedb-enterprise)}"
: "${TARGET_BRANCH:=main}"
: "${UPSTREAM_BRANCH:=main}"

TARGET_REMOTE="${TARGET_REMOTE:-$(git remote -v 2>/dev/null | awk -v repo="$TARGET_REPO" '$2 ~ repo "(\\.git)?/?$" {print $1; exit}')}"
: "${TARGET_REMOTE:=origin}"

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-$(git remote -v 2>/dev/null | awk -v repo="$UPSTREAM_REPO" '$2 ~ repo "(\\.git)?/?$" {print $1; exit}')}"
: "${UPSTREAM_REMOTE:=upstream}"

# --- Helper Functions ---

slack_mention_for_user() {
  local user="$1"
  local mapped=""

  resolve_one() {
    local target_user
    target_user="$(tr '[:upper:]' '[:lower:]' <<<"$1")"
    while IFS='=' read -r github_user slack_mention; do
      github_user="$(tr '[:upper:]' '[:lower:]' <<<"$github_user")"
      if [[ "$github_user" == "$target_user" ]]; then
        echo "$slack_mention"
        return 0
      fi
    done <<<"${USERNAME_MAPPING_GITHUB_TO_SLACK:-}"
    return 1
  }

  if mapped=$(resolve_one "$user"); then
    echo "$mapped"
    return
  fi

  if [[ -n "${APPROVERS:-}" ]]; then
    local mentions=""
    IFS=',' read -ra ADDR <<<"$APPROVERS"
    for approver in "${ADDR[@]}"; do
      approver="$(echo "$approver" | xargs)"
      if mapped=$(resolve_one "$approver"); then
        mentions="${mentions} ${mapped}"
      fi
    done
    mentions="$(echo "$mentions" | xargs)"
    if [[ -n "$mentions" ]]; then
      echo "$mentions"
      return
    fi
  fi

  echo "<!here>"
}

write_conflict_slack_payload() {
  local commit_sha="$1"
  local commit_json github_user commit_author commit_message slack_mention run_url

  commit_json=$(gh api "repos/${UPSTREAM_REPO}/commits/$commit_sha")

  github_user=$(jq -r '.author.login // .committer.login // ""' <<<"$commit_json")
  commit_author=$(jq -r '.commit.author.name' <<<"$commit_json")
  commit_message=$(jq -r '.commit.message | split("\n")[0]' <<<"$commit_json")

  slack_mention=$(slack_mention_for_user "$github_user")

  run_url=""
  if [[ -n "${GITHUB_SERVER_URL:-}" && -n "${GITHUB_REPOSITORY:-}" && -n "${GITHUB_RUN_ID:-}" ]]; then
    run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  fi

  jq -n \
    --arg mention "$slack_mention" \
    --arg repo "${UPSTREAM_REPO}" \
    --arg workflow "${GITHUB_WORKFLOW:-Upstream Rebase}" \
    --arg author "$commit_author" \
    --arg message "$commit_message" \
    --arg run_url "$run_url" \
    '{
      text: ("🔧 Upstream Rebase Needs Resolution - " + $mention + " (" + $author + ")"),
      attachments: [{
        color: "warning",
        fields: (
          [
            {title: "Repository", value: $repo, short: true},
            {title: "Workflow", value: $workflow, short: true},
            {title: "Commit Author", value: $author, short: true}
          ]
          + (if $run_url == "" then [] else [{title: "View Logs", value: ("<" + $run_url + "|Click here>"), short: true}] end)
          + (if $message == "" then [] else [{title: "Commit Message", value: $message, short: false}] end)
        )
      }]
    }' >/tmp/rebase-conflict-slack-payload.json
}

report_rebase_conflict() {
  local commit_sha="$1"
  local conflict_lines="$2"
  local rule
  rule="$(printf '─%.0s' {1..78})"

  echo
  echo "$rule"
  echo "❌  UPSTREAM REBASE CONFLICT"
  echo "$rule"
  echo
  echo "Could not replay the target patches on top of this upstream commit:"
  echo
  git log -1 \
    --format='  commit   %H%n  subject  %s%n  author   %an <%ae>%n  date     %ad' \
    --date=short "$commit_sha"
  echo "  link     https://github.com/${UPSTREAM_REPO}/commit/$commit_sha"
  echo
  echo "Conflicts to resolve (then 'git add' each path):"
  if [[ -n "$conflict_lines" ]]; then
    while IFS= read -r conflict; do
      echo "  • $conflict"
    done <<<"$conflict_lines"
  else
    echo "  (no CONFLICT lines captured — run 'git status' to inspect)"
  fi
  echo
  echo "$rule"
  echo "How to resolve (run locally from an up-to-date '${TARGET_BRANCH}'):"
  echo "$rule"
  echo "  1. Reproduce the conflict locally:"
  echo "       scripts/sync-upstream.sh rebase"
  echo "  2. Fix the conflicted files above, then continue the rebase:"
  echo "       git add . && git rebase --continue"
  echo "  3. Push the resolved patch branch:"
  echo "       git push ${TARGET_REMOTE} HEAD"
  echo "  4. In GitHub: Actions → 'Promote Target Patch Branch to Main',"
  echo "     run it against the target-patch-* branch you just pushed."
  echo "     It waits for manual approval, verifies CI on the patch branch,"
  echo "     then promotes it as the new '${TARGET_BRANCH}'."
  echo "$rule"
  echo
}

poll_ci_status() {
  local branch_name="$1"
  local timeout="6000" # 100 minutes (6000 seconds)
  local interval="120" # 2 minutes (120 seconds)

  local commit_sha
  commit_sha=$(git rev-parse "${TARGET_REMOTE}/$branch_name")

  local elapsed=0

  while [[ $elapsed -lt $timeout ]]; do
    echo "Checking CI status... (${elapsed}s elapsed)"

    local api_response
    api_response=$(gh api "repos/${TARGET_REPO}/commits/$commit_sha/check-runs" --paginate)

    local ci_check_filter='.name != "Rebase Target on Upstream" and .name != "Promote Target Patch Branch to Main" and .name != "Upstream Rebase"'

    local total_checks completed_checks success_checks failure_checks cancelled_checks pending_checks
    total_checks=$(echo "$api_response" | jq -r -s "[.[].check_runs[] | select($ci_check_filter)] | length")
    completed_checks=$(echo "$api_response" | jq -r -s "[.[].check_runs[] | select($ci_check_filter and .status == \"completed\")] | length")
    success_checks=$(echo "$api_response" | jq -r -s "[.[].check_runs[] | select($ci_check_filter and .status == \"completed\" and .conclusion == \"success\")] | length")
    failure_checks=$(echo "$api_response" | jq -r -s "[.[].check_runs[] | select($ci_check_filter and .status == \"completed\" and .conclusion == \"failure\")] | length")
    cancelled_checks=$(echo "$api_response" | jq -r -s "[.[].check_runs[] | select($ci_check_filter and .status == \"completed\" and .conclusion == \"cancelled\")] | length")
    pending_checks=$(echo "$api_response" | jq -r -s "[.[].check_runs[] | select($ci_check_filter and .status != \"completed\")] | length")

    echo "CI Status: $completed_checks/$total_checks completed, $success_checks success, $failure_checks failure, $cancelled_checks cancelled, $pending_checks pending"

    if [[ "$failure_checks" -gt 0 ]]; then
      echo "❌ CI validation failed: $failure_checks out of $total_checks checks failed"
      echo "$api_response" | jq -r -s ".[] | .check_runs[] | select($ci_check_filter and .status == \"completed\" and .conclusion == \"failure\") | \"  • \(.name): \(.conclusion // \"unknown\") - \(.html_url)\""
      return 1
    elif [[ "$cancelled_checks" -gt 0 ]]; then
      echo "⚠️ Found $cancelled_checks cancelled checks. Attempting to restart them..."
      local cancelled_jobs
      cancelled_jobs=$(echo "$api_response" | jq -r -s "[.[].check_runs[]] | .[] | select($ci_check_filter and .status == \"completed\" and .conclusion == \"cancelled\") | \"\(.id)\t\(.name)\"")

      while IFS=$'\t' read -r job_id job_name; do
        [[ -z "$job_id" ]] && continue
        echo "Restarting job $job_name ($job_id)..."
        gh api -X POST "repos/${TARGET_REPO}/actions/jobs/$job_id/rerun" --silent || echo "⚠️ Failed to restart job $job_name ($job_id) via API"
      done <<<"$cancelled_jobs"

      echo "Waiting 10 seconds for restarted jobs to register..."
      sleep 10
      continue
    elif [[ "$completed_checks" -eq "$total_checks" && "$total_checks" -gt 0 ]]; then
      echo "✅ CI validation passed: All $total_checks checks completed successfully"
      return 0
    fi

    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo "❌ CI validation timed out after ${timeout}s"
  return 2
}

do_rebase() {
  if ! git diff-index --quiet HEAD || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    echo "❌ Uncommitted changes detected in working directory. Please stash or commit your changes before running this script"
    exit 1
  fi

  if ! git remote | grep -q "${UPSTREAM_REMOTE}"; then
    git remote add "${UPSTREAM_REMOTE}" "$UPSTREAM_REPO_URL"
  fi

  git fetch "${UPSTREAM_REMOTE}"
  git fetch "${TARGET_REMOTE}"

  local TOTAL_PENDING
  TOTAL_PENDING=$(git rev-list --count "${TARGET_REMOTE}/${TARGET_BRANCH}..${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}")

  if [[ "$TOTAL_PENDING" -eq 0 ]]; then
    echo "✅ No commits to process. Repository is already up to date with upstream."
    exit 0
  fi

  local PATCH_BRANCH_NAME
  PATCH_BRANCH_NAME="target-patch-$(date -u +%Y-%m-%d-%H%M%S)"
  git checkout -b "$PATCH_BRANCH_NAME" "${TARGET_REMOTE}/${TARGET_BRANCH}"

  local CURRENT_HEAD
  CURRENT_HEAD=$(git rev-parse --short HEAD)
  local UPSTREAM_HEAD
  UPSTREAM_HEAD=$(git rev-parse --short "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}")

  echo ""
  echo "✅ Created patch branch '$PATCH_BRANCH_NAME' from ${TARGET_REMOTE}/${TARGET_BRANCH} ($CURRENT_HEAD)"
  echo "Applying $TOTAL_PENDING upstream commit(s): ${TARGET_REMOTE}/${TARGET_BRANCH}..$UPSTREAM_HEAD"

  local PROCESSED_COUNT=0
  while true; do
    local NEXT_COMMIT
    NEXT_COMMIT=$(git rev-list "HEAD..${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}" | tail -n 1)
    if [[ -z $NEXT_COMMIT ]]; then
      break
    fi

    if ! git merge-base --is-ancestor "$NEXT_COMMIT" "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"; then
      echo "❌ Commit $NEXT_COMMIT is not an ancestor of ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}. This should not happen."
      exit 1
    fi

    echo "[$((PROCESSED_COUNT + 1))/$TOTAL_PENDING] $(git log -1 --format='%h  %s' "$NEXT_COMMIT")"

    local rebase_output
    if rebase_output="$(git -c advice.mergeConflict=false rebase "$NEXT_COMMIT" 2>&1)"; then
      PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    else
      local conflict_lines
      conflict_lines="$(tr '\r' '\n' <<<"$rebase_output" | grep '^CONFLICT' || true)"
      if [[ -z "$conflict_lines" ]]; then
        echo "$rebase_output"
      fi
      report_rebase_conflict "$NEXT_COMMIT" "$conflict_lines"
      write_conflict_slack_payload "$NEXT_COMMIT"
      exit 1
    fi
  done

  if [[ "$PROCESSED_COUNT" -gt 0 ]]; then
    echo "Pushing patch branch to trigger CI..."
    git push --set-upstream "${TARGET_REMOTE}" "$PATCH_BRANCH_NAME"

    echo "Waiting for CI validation to complete..."
    if ! poll_ci_status "$PATCH_BRANCH_NAME"; then
      echo "❌ CI VALIDATION FAILED"
      echo "Patch branch '$PATCH_BRANCH_NAME' preserved for investigation."
      echo ""
      echo "To investigate:"
      echo "1. View failed checks: https://github.com/${TARGET_REPO}/actions"
      echo "2. Check out the branch: git checkout $PATCH_BRANCH_NAME"
      echo "3. Fix issues and push your fixes"
      echo "4. Use the promotion job to submit it"
      exit 1
    fi

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
      echo "branch_name=$PATCH_BRANCH_NAME" >>"$GITHUB_OUTPUT"
    fi

    echo "✅ Patch branch '$PATCH_BRANCH_NAME' is ready for promotion."
  fi
}

do_promote() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: $0 promote <branch-name>" >&2
    exit 1
  fi

  local BRANCH_NAME="$1"
  read -r BRANCH_NAME <<<"$BRANCH_NAME"

  if ! [[ "$BRANCH_NAME" =~ ^target-patch-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ ]]; then
    echo "❌ Invalid branch name format: $BRANCH_NAME. Branch name must match pattern: target-patch-YYYY-MM-DD-HHMMSS"
    exit 1
  fi

  git fetch "${TARGET_REMOTE}"
  git fetch "${TARGET_REMOTE}" "$BRANCH_NAME:$BRANCH_NAME"

  echo "Polling CI status for branch: $BRANCH_NAME"

  if poll_ci_status "$BRANCH_NAME"; then
    echo "✅ CI validation passed!"
  else
    local CI_EXIT_CODE=$?
    echo "❌ CI validation failed"
    echo "❌ Branch '$BRANCH_NAME' will not be promoted to ${TARGET_BRANCH}"
    echo "❌ "
    echo "❌ Next steps:"
    echo "❌ 1. Check CI logs at https://github.com/${TARGET_REPO}/commit/${BRANCH_NAME}"
    echo "❌ 2. Fix any issues in the branch"
    echo "❌ 3. Push fixes to '$BRANCH_NAME'"
    echo "❌ 4. Re-run this script to try again"
    exit "$CI_EXIT_CODE"
  fi

  local TAG_NAME
  TAG_NAME="manual-promotion-history-$(date -u +%Y-%m-%d-%H%M%S)"
  echo "Current ${TARGET_BRANCH} branch points to: $(git rev-parse --short "${TARGET_REMOTE}/${TARGET_BRANCH}")"
  echo "Creating backup tag: $TAG_NAME"
  git tag "$TAG_NAME" "${TARGET_REMOTE}/${TARGET_BRANCH}"
  git push "${TARGET_REMOTE}" "$TAG_NAME"

  echo "Promoting '$BRANCH_NAME' to ${TARGET_BRANCH} branch..."
  git fetch "${TARGET_REMOTE}" # Fetch to ensure we have the latest lease
  git push --force-with-lease "${TARGET_REMOTE}" "$BRANCH_NAME:${TARGET_BRANCH}"
  git push "${TARGET_REMOTE}" --delete "$BRANCH_NAME"
}

# --- Subcommand Router ---
sync_core_main() {
  local COMMAND="${1:-}"
  if [[ -n "$COMMAND" ]]; then
    shift
  fi

  case "$COMMAND" in
    rebase)
      do_rebase "$@"
      ;;
    promote)
      do_promote "$@"
      ;;
    *)
      echo "Usage: $0 {rebase|promote} [args...]"
      exit 1
      ;;
  esac
}
