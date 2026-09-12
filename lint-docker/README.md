# Lint Docker

Composite action to lint Dockerfiles with Hadolint.

## Usage

```yaml
- name: Lint Dockerfiles
  uses: paradedb/actions/lint-docker@v12
```

Inputs:

- `directory`: Directory to search for `Dockerfile*` files (default `docker`).
- `exclude`: Path to exclude (default `docker/Dockerfile.template`).
- `config`: Repository-owned Hadolint configuration (default `.hadolint.yaml`).

Hadolint treats informational findings as errors. If no Dockerfiles match, the lint step is skipped. Keep Dockerfile generation and template-consistency checks in the calling workflow.
