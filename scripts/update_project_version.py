#!/usr/bin/env python3

"""Update project.godot [application] config/version.

Idempotent: replaces existing config/version or inserts it under [application].
"""

from __future__ import annotations

import argparse
from pathlib import Path


def update_version(path: Path, version: str) -> None:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)

    out: list[str] = []
    in_app = False
    found = False
    inserted = False

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            if in_app and not found and not inserted:
                out.append(f'config/version="{version}"\n')
                inserted = True
            in_app = stripped == "[application]"
            out.append(line)
            continue

        if in_app and stripped.startswith("config/version="):
            out.append(f'config/version="{version}"\n')
            found = True
            continue

        if in_app and (not found) and (not inserted) and stripped.startswith("run/main_scene="):
            out.append(f'config/version="{version}"\n')
            inserted = True
            out.append(line)
            continue

        out.append(line)

    if in_app and not found and not inserted:
        out.append(f'config/version="{version}"\n')

    path.write_text("".join(out), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", default="project.godot")
    ap.add_argument("--version", required=True)
    args = ap.parse_args()

    p = Path(args.project)
    update_version(p, args.version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
