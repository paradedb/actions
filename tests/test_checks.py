import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / name / "check.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


FORMAT = load("lint-format")
BASH = load("lint-bash")


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.previous = Path.cwd()
        os.chdir(self.temp.name)
        self.addCleanup(os.chdir, self.previous)
        subprocess.run(["git", "init", "-q"], check=True)
        self.environment = patch.dict(os.environ, {
            "FORMAT_EXCLUDE": "", "CHECK_JSON": "false",
            "SHELL_FORMATTER": "beautysh", "ALLOW_SH": "false",
            "STRICT_MODE_EXCLUDE": "", "SOURCE_PATH": "scripts",
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def track(self, name, data):
        path = Path(name)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        subprocess.run(["git", "add", "--", name], check=True)

    def test_empty_checkout(self):
        self.assertEqual(FORMAT.check(), 0)
        self.assertEqual(BASH.check(), 0)

    def test_format_handles_spaces_and_binary(self):
        self.track("a file.txt", b"hello\n")
        self.track("binary.bin", b"\x00\xff")
        self.assertEqual(FORMAT.check(), 0)
        Path("a file.txt").write_bytes(b"hello \n")
        self.assertEqual(FORMAT.check(), 1)
        Path("a file.txt").write_bytes(b"hello")
        self.assertEqual(FORMAT.check(), 1)

    def test_git_exclusions_do_not_exclude_json_or_crlf(self):
        self.track("docs/a.txt", b"hello ")
        os.environ["FORMAT_EXCLUDE"] = "docs/*\n"
        self.assertEqual(FORMAT.check(), 0)
        Path("docs/a.txt").write_bytes(b"hello\r\n")
        self.assertEqual(FORMAT.check(), 1)
        Path("docs/a.txt").write_bytes(b"hello\n")
        self.track("docs/b.json", b"{\n")
        os.environ["CHECK_JSON"] = "true"
        self.assertEqual(FORMAT.check(), 1)

    def test_json_validation_is_optional(self):
        self.track("invalid.json", b"{\n")
        self.assertEqual(FORMAT.check(), 0)
        os.environ["CHECK_JSON"] = "true"
        self.assertEqual(FORMAT.check(), 1)

    def run_bash(self):
        # Real Git discovery; capture only the external formatter/linter commands.
        real_run = subprocess.run
        calls = []

        def run(command, **kwargs):
            if command[0] == "git":
                return real_run(command, **kwargs)
            calls.append(command)
            self.assertNotIn("shell", kwargs)
            return subprocess.CompletedProcess(command, 0)

        with patch.object(BASH.subprocess, "run", side_effect=run):
            result = BASH.check()
        return result, calls

    def test_shell_metacharacters_and_hidden_directories(self):
        name = ".github/a file; echo injected.sh"
        self.track(name, b"#!/usr/bin/env bash\nset -euo pipefail\n")
        result, calls = self.run_bash()
        self.assertEqual(result, 0)
        self.assertEqual(len(calls), 2)
        self.assertTrue(all(command[-1] == "./" + name for command in calls))

    def test_shebang_and_strict_mode_exceptions(self):
        self.track("bootstrap.sh", b"#!/bin/sh\necho hello\n")
        self.assertEqual(self.run_bash()[0], 1)
        os.environ["ALLOW_SH"] = "true"
        self.assertEqual(self.run_bash()[0], 1)
        os.environ["STRICT_MODE_EXCLUDE"] = "bootstrap.sh"
        self.assertEqual(self.run_bash()[0], 0)

    def test_skip_annotation_and_untracked_files(self):
        self.track("ok.sh", b"#!/bin/bash\n# @paradedb-skip-check-pipefail\n")
        Path("untracked.sh").write_text("bad")
        self.assertEqual(self.run_bash()[0], 0)

    def test_shfmt_and_custom_source_path(self):
        self.track("ok.sh", b"#!/bin/bash\nset -Eeuo pipefail\n")
        os.environ["SHELL_FORMATTER"] = "shfmt"
        os.environ["SOURCE_PATH"] = ".github/scripts"
        result, calls = self.run_bash()
        self.assertEqual(result, 0)
        self.assertEqual(calls[0][1:-1], ["-d", "-i", "2", "-ci", "--"])
        self.assertIn(".github/scripts", calls[1])


if __name__ == "__main__":
    unittest.main()
