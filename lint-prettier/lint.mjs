import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

function run(command, args) {
  const result = spawnSync(command, args, { stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

const source = process.env.PRETTIER_SOURCE;
if (!["shared", "pnpm"].includes(source)) {
  throw new Error("prettier-source must be shared or pnpm");
}
if (process.env.LINT_MARKDOWN === "true") {
  run(process.execPath, [
    fileURLToPath(
      new URL("node_modules/markdownlint-cli/markdownlint.js", import.meta.url),
    ),
    "**/*.md",
    "--ignore",
    "**/node_modules/**",
  ]);
}
const patterns = process.env.LINT_PATTERNS.split(/\r?\n/).filter(Boolean);
if (!patterns.length)
  throw new Error("At least one Prettier pattern is required");
const ignoreArgs = process.env.PRETTIER_IGNORE_PATH
  ? ["--ignore-path", process.env.PRETTIER_IGNORE_PATH]
  : [];
if (source === "pnpm") {
  run("pnpm", ["exec", "prettier", "--check", ...patterns, ...ignoreArgs]);
} else {
  run(process.execPath, [
    fileURLToPath(
      new URL("node_modules/prettier/bin/prettier.cjs", import.meta.url),
    ),
    "--check",
    ...patterns,
    ...ignoreArgs,
  ]);
}
