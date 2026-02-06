#!/usr/bin/env python3

"""Extract a version section from CHANGELOG.md.

Looks for a heading like:
  ## v1.2.3 - YYYY-MM-DD

and outputs that section (heading + bullets) until the next '## ' heading.
"""

from __future__ import annotations

import argparse
from pathlib import Path


def extract(changelog: str, version: str) -> str:
    lines = changelog.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.startswith("## ") and line.split(" ", 2)[1] == version:
            start = i
            break
    if start is None:
        return ""

    out = [lines[start]]
    for j in range(start + 1, len(lines)):
        l = lines[j]
        if l.startswith("## "):
            break
        out.append(l)

    while out and out[-1].strip() == "":
        out.pop()
    return "\n".join(out).strip() + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    ap.add_argument("--changelog", default="CHANGELOG.md")
    ap.add_argument("--out", default="dist/RELEASE_NOTES.md")
    args = ap.parse_args()

    cl_path = Path(args.changelog)
    notes = extract(cl_path.read_text(encoding="utf-8"), args.version)
    if not notes:
        notes = f"## {args.version}\n\n- No release notes found.\n"

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(notes, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
