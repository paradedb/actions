import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const script = fileURLToPath(
  new URL("../lint-prettier/lint.mjs", import.meta.url),
);

function fixture(t) {
  const cwd = mkdtempSync(join(tmpdir(), "paradedb-lint-test-"));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  return cwd;
}

function run(cwd, env = {}) {
  return spawnSync(process.execPath, [script], {
    cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      PRETTIER_SOURCE: "shared",
      LINT_MARKDOWN: "false",
      LINT_PATTERNS: "**/*.{yml,yaml}",
      ...env,
    },
  });
}

test("YAML respects caller configuration and ignore file", (t) => {
  const cwd = fixture(t);
  writeFileSync(join(cwd, ".prettierignore"), "ignored.yaml\n");
  writeFileSync(join(cwd, "ignored.yaml"), "invalid: [\n");
  writeFileSync(join(cwd, "a file.yaml"), "key: value\n");
  assert.equal(run(cwd).status, 0);
  writeFileSync(join(cwd, "a file.yaml"), "key:    value\n");
  assert.equal(run(cwd).status, 1);
});

test("Markdown ignores nested dependencies and uses caller lint rules", (t) => {
  const cwd = fixture(t);
  mkdirSync(join(cwd, "nested/node_modules/package"), { recursive: true });
  writeFileSync(join(cwd, "nested/node_modules/package/bad.md"), "#bad\n");
  writeFileSync(join(cwd, ".markdownlint.yaml"), "MD013: false\n");
  writeFileSync(
    join(cwd, "README.md"),
    "# Heading\n\n" + "Long text ".repeat(20).trim() + "\n",
  );
  const env = { LINT_MARKDOWN: "true", LINT_PATTERNS: "{**/*.md,**/*.mdx}" };
  const result = run(cwd, env);
  assert.equal(result.status, 0, result.stdout + result.stderr);
  writeFileSync(join(cwd, "README.md"), "# Heading\n\n# Heading\n");
  assert.equal(run(cwd, env).status, 1);
});

test("pnpm mode invokes the caller Prettier with literal pattern arguments", (t) => {
  const cwd = fixture(t);
  mkdirSync(join(cwd, "bin"));
  writeFileSync(join(cwd, "bin/pnpm"), '#!/bin/sh\nprintf "%s\\n" "$@"\n', {
    mode: 0o755,
  });
  const result = run(cwd, {
    PRETTIER_SOURCE: "pnpm",
    PATH: join(cwd, "bin") + ":" + process.env.PATH,
    LINT_PATTERNS: "a file.yaml\n$(touch injected).yaml",
  });
  assert.equal(result.status, 0);
  assert.equal(
    result.stdout,
    "exec\nprettier\n--check\na file.yaml\n$(touch injected).yaml\n",
  );
});

test("invalid configuration fails instead of silently skipping", (t) => {
  const cwd = fixture(t);
  assert.notEqual(run(cwd, { PRETTIER_SOURCE: "unknown" }).status, 0);
  assert.notEqual(run(cwd, { LINT_PATTERNS: "" }).status, 0);
});
