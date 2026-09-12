import os
from pathlib import Path
import re
import subprocess
import sys


def check():
    formatter = os.environ.get("SHELL_FORMATTER", "beautysh")
    if formatter not in ("beautysh", "shfmt"):
        raise ValueError("formatter must be beautysh or shfmt")
    files = subprocess.check_output(["git", "ls-files", "-z", "*.sh"]).split(b"\0")
    files = [os.fsdecode(file) for file in files if file]
    if not files:
        print("No tracked shell scripts found.")
        return 0
    excluded = set(os.environ.get("STRICT_MODE_EXCLUDE", "").splitlines())
    shebangs = ["#!/bin/bash", "#!/usr/bin/env bash"]
    if os.environ.get("ALLOW_SH") == "true":
        shebangs.append("#!/bin/sh")
    tools = Path(sys.executable).parent
    failed = False
    for file in files:
        text = Path(file).read_text()
        if not text.splitlines() or text.splitlines()[0] not in shebangs:
            print("Missing supported shebang:", file)
            failed = True
        if file not in excluded and not re.search(
            r"^(?:[ \t]*set -E?euo pipefail|# @paradedb-skip-check-pipefail)$", text, re.MULTILINE
        ):
            print("Missing strict mode:", file)
            failed = True
        args = ["--indent-size", "2", "--check", "--"] if formatter == "beautysh" else ["-d", "-i", "2", "-ci", "--"]
        # Match the existing Bash **/*.sh formatter glob, which omits hidden
        # directories. Shebang, strict-mode, and ShellCheck still cover them.
        commands = []
        if not any(part.startswith(".") for part in Path(file).parts):
            commands.append([str(tools / formatter), *args, "./" + file])
        commands.append([
            str(tools / "shellcheck"), "-x", "-P",
            os.environ.get("SOURCE_PATH", "scripts"), "--", "./" + file,
        ])
        for command in commands:
            if subprocess.run(command, check=False).returncode:
                failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(check())
