#!/bin/bash

set -euo pipefail

webhook_url="${SLACK_ALERT_WEBHOOK_URL:-}"

if [[ -z "$webhook_url" ]]; then
  echo "Slack webhook not configured, skipping notification"
  exit 0
fi

payload_file="${SLACK_ALERT_PAYLOAD_FILE:-}"

if [[ -n "$payload_file" && -f "$payload_file" ]]; then
  json_data="$(cat "$payload_file")"
else
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to generate a Slack alert payload"
    exit 1
  fi

  title="${SLACK_ALERT_TITLE:-GitHub Actions Workflow Failed}"
  text="${SLACK_ALERT_TEXT:-}"
  mention="${SLACK_ALERT_MENTION:-}"
  color="${SLACK_ALERT_COLOR:-danger}"
  repository="${SLACK_ALERT_REPOSITORY:-${GITHUB_REPOSITORY:-unknown}}"
  branch="${SLACK_ALERT_BRANCH:-${GITHUB_REF_NAME:-}}"
  workflow="${SLACK_ALERT_WORKFLOW:-${GITHUB_WORKFLOW:-unknown}}"
  actor="${SLACK_ALERT_ACTOR:-${GITHUB_ACTOR:-}}"
  run_id="${SLACK_ALERT_RUN_ID:-${GITHUB_RUN_ID:-}}"
  run_url="${SLACK_ALERT_RUN_URL:-}"

  if [[ -z "$run_url" && -n "${GITHUB_SERVER_URL:-}" && -n "${GITHUB_REPOSITORY:-}" && -n "${GITHUB_RUN_ID:-}" ]]; then
    run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  fi

  if [[ -z "$text" ]]; then
    text="🚨 ${title}"
    if [[ -n "$mention" ]]; then
      text="${text} - ${mention}"
    fi
  fi

  json_data="$(
    jq -n \
      --arg text "$text" \
      --arg color "$color" \
      --arg repository "$repository" \
      --arg branch "$branch" \
      --arg workflow "$workflow" \
      --arg actor "$actor" \
      --arg run_id "$run_id" \
      --arg run_url "$run_url" \
      '
        def field($title; $value; $short):
          if $value == "" then empty else {title: $title, value: $value, short: $short} end;

        {
          text: $text,
          attachments: [{
            color: $color,
            fields: [
              field("Repository"; $repository; true),
              field("Branch"; $branch; true),
              field("Workflow"; $workflow; true),
              field("Triggered By"; $actor; true),
              field("Run ID"; $run_id; true),
              (if $run_url == "" then empty else {title: "View Logs", value: ("<" + $run_url + "|Click here>"), short: false} end)
            ]
          }]
        }
      '
  )"
fi

# Slack answers "ok" on success and "invalid_payload" on a malformed body,
# both over HTTP, so a rejected notification otherwise looks like a passing step.
response="$(
  curl -sS -X POST \
    -H "Content-type: application/json" \
    --data "$json_data" \
    "$webhook_url"
)"

if [[ "$response" != "ok" ]]; then
  echo "Slack rejected the notification: $response"
  echo "Payload was: $json_data"
  exit 1
fi
