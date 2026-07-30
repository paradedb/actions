# Slack Alert

`slack-alert` is a composite action that posts standardized GitHub Actions alerts to Slack.
It accepts a webhook URL, an optional Slack mention, and optional metadata fields, then verifies that Slack accepted the payload.
It also supports posting a pre-rendered Slack payload from a file for workflows that need custom formatting.

## Usage

Use `slack-alert` from workflow failure handlers that need to page a Slack user group without duplicating payload construction and response validation.

```yaml
- name: Notify Slack on Failure
  if: failure()
  uses: paradedb/actions/slack-alert@v10
  with:
    webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
    mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
    title: "${{ github.workflow }} workflow failed"
    branch: ${{ github.ref_name }}
```

For custom Slack payloads, write the JSON body to a file and pass `payload_file`.
When the file exists, the action posts it as-is.

```yaml
- name: Notify Slack on Failure
  if: failure()
  uses: paradedb/actions/slack-alert@v10
  with:
    webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
    payload_file: /tmp/slack-payload.json
```

## Inputs

| Input          | Description                                                                                    | Default                          |
| -------------- | ---------------------------------------------------------------------------------------------- | -------------------------------- |
| `webhook_url`  | Slack incoming webhook URL. If empty, the alert is skipped.                                    | `""`                             |
| `mention`      | Optional Slack mention to append to generated alert text.                                      | `""`                             |
| `title`        | Alert title used when `text` and `payload_file` are not provided.                              | `GitHub Actions Workflow Failed` |
| `text`         | Exact Slack text to send instead of generating text from title and mention.                    | `""`                             |
| `color`        | Slack attachment color for generated payloads.                                                 | `danger`                         |
| `payload_file` | Optional path to a complete Slack JSON payload. If the file exists, it is posted as-is.        | `""`                             |
| `repository`   | Repository field for generated payloads. Defaults to `GITHUB_REPOSITORY`.                      | `""`                             |
| `branch`       | Optional branch field for generated payloads. Defaults to `GITHUB_REF_NAME`.                   | `""`                             |
| `workflow`     | Workflow field for generated payloads. Defaults to `GITHUB_WORKFLOW`.                          | `""`                             |
| `actor`        | Optional actor field for generated payloads. Defaults to `GITHUB_ACTOR`.                       | `""`                             |
| `run_id`       | Optional run ID field for generated payloads. Defaults to `GITHUB_RUN_ID`.                     | `""`                             |
| `run_url`      | Run URL for generated payloads. Defaults to the current GitHub Actions run URL when available. | `""`                             |
