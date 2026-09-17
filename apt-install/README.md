# APT Install with Retry

Composite action to install APT packages with retry, exponential backoff, and index refresh.

## Usage

```yaml
- name: Install Dependencies
  uses: paradedb/actions/apt-install@v13
  with:
    packages: >-
      sudo wget git ca-certificates curl gnupg gpg lsb-release
      pkg-config libssl-dev jq gettext-base lld
```

Inputs:

- `packages`: Space-separated list of APT packages and options (required).
