# Build pg_search from source

Compile the checked-out community or enterprise source with its pinned Rust and
cargo-pgrx versions. Run from the source repository root on a Debian/Ubuntu runner
(or container) with sudo. The build is native: choose a runner architecture and
libc compatible with the image that will consume the artifacts.

```yaml
- uses: actions/checkout@v7
- uses: paradedb/actions/build-pg_search-source@v13
  id: build
  with:
    pg-version: "18"
    profile: release
```

`artifacts-dir` contains `usr/lib/postgresql/<major>/lib` and
`usr/share/postgresql/<major>/extension`. Consumers package or copy that tree into
their image. This action does not check out source, publish images, or deploy.

The optional `features`, `target`, and `target-rustflags` inputs preserve the
Antithesis instrumentation build. `cache-prefix-key`, `cache-save`, and
`cache-on-failure` configure caching. Use separate prefixes for incompatible
profiles, architectures, and source repositories. Toolchain setup intentionally
lives inside this action so callers do not need repository-local actions.
