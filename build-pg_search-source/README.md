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

The `artifacts-dir` output (`${{ steps.build.outputs.artifacts-dir }}`) contains
extension files under `usr/lib/postgresql/<major>/lib` and
`usr/share/postgresql/<major>/extension`, ready to package or copy into an image.

Optional `with:` inputs configure Cargo features, target, compiler flags, and
caching. See [action.yml](action.yml) for their names and defaults.
