# Build pg_search from Source

Compile the checked-out community or enterprise source with its pinned Rust and
cargo-pgrx versions. Run from the source repository root on a Debian/Ubuntu runner
(or container) with sudo. The build is native: choose a runner architecture and
libc compatible with the image that will consume the artifacts.

```yaml
- name: Build pg_search from Source
  uses: paradedb/actions/build-pg_search-source@v13
  id: build
  with:
    pg-version: "18"
    profile: release
```

The action returns an `artifacts-dir` output: the path to the staged extension
files. With `id: build` above, subsequent steps can read it as
`${{ steps.build.outputs.artifacts-dir }}`. That directory contains
`usr/lib/postgresql/<major>/lib` and `usr/share/postgresql/<major>/extension`,
ready to package or copy into an image.

The example uses the default build settings. For custom builds, add optional
inputs under `with:`: `features`, `target`, and `target-rustflags` control Cargo
features, the Rust target, and compiler flags. The `cache-prefix-key`, `cache-save`,
and `cache-on-failure` inputs control caching. See [action.yml](action.yml) for
all inputs and their defaults.
