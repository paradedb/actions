import json
import os
from pathlib import Path
import subprocess
import sys


def git(*args, allow_no_matches=False):
    result = subprocess.run(["git", *args], stdout=subprocess.PIPE, check=False)
    if result.returncode and not (allow_no_matches and result.returncode == 1):
        raise subprocess.CalledProcessError(result.returncode, result.args)
    return result.stdout


def check():
    failed = False
    for entry in git("ls-files", "--eol", "-z").split(b"\0"):
        if entry and b"crlf" in entry.split(b"\t", 1)[0]:
            print("Incorrect line endings:", os.fsdecode(entry))
            failed = True
    exclusions = [":(exclude)" + p for p in os.environ.get("FORMAT_EXCLUDE", "").splitlines() if p]
    for file in git("grep", "-Ilz", "[[:blank:]]$", "--", *exclusions, allow_no_matches=True).split(b"\0"):
        if file:
            print("Trailing whitespace:", os.fsdecode(file))
            failed = True
    for file in git("grep", "-Ilz", ".", "--", *exclusions, allow_no_matches=True).split(b"\0"):
        if file:
            path = Path(os.fsdecode(file))
            if path.stat().st_size:
                with path.open("rb") as stream:
                    stream.seek(-1, 2)
                    if stream.read(1) != b"\n":
                        print("Missing final newline:", path)
                        failed = True
    if os.environ.get("CHECK_JSON") == "true":
        for file in git("ls-files", "-z", "*.json").split(b"\0"):
            if file:
                try:
                    json.loads(Path(os.fsdecode(file)).read_text())
                except (ValueError, UnicodeError) as error:
                    print("Invalid JSON:", os.fsdecode(file), error)
                    failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(check())
