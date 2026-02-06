#!/usr/bin/env python3

"""Generate a short changelog section from git history.

This script is designed to be automation-friendly:
- Requires git.
- Produces concise bullets.
- If no tags exist, it uses the full history.

Optional AI summarization can be added later; the deterministic mode is the default.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from urllib import request


def run(cmd: list[str]) -> str:
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    return out.decode("utf-8", errors="replace").strip()


def try_run(cmd: list[str]) -> str:
    try:
        return run(cmd)
    except subprocess.CalledProcessError:
        return ""


def is_git_repo() -> bool:
    return try_run(["git", "rev-parse", "--is-inside-work-tree"]) == "true"


def last_tag() -> str:
    return try_run(["git", "describe", "--tags", "--abbrev=0"])


def commits_since(ref: str | None) -> list[str]:
    if ref:
        rng = f"{ref}..HEAD"
        raw = run(["git", "log", rng, "--no-merges", "--format=%s"])
    else:
        raw = run(["git", "log", "--no-merges", "--format=%s"])
    lines = [l.strip() for l in raw.splitlines() if l.strip()]
    return lines


def normalize_bullet(msg: str) -> str:
    msg = msg.strip()
    msg = msg.replace("\t", " ")
    while "  " in msg:
        msg = msg.replace("  ", " ")
    # Remove common prefixes.
    prefixes = [
        "feat:",
        "feature:",
        "fix:",
        "chore:",
        "docs:",
        "refactor:",
        "test:",
        "perf:",
    ]
    lower = msg.lower()
    for p in prefixes:
        if lower.startswith(p):
            msg = msg[len(p) :].strip()
            break
    if msg and msg[0].islower():
        msg = msg[0].upper() + msg[1:]
    return msg


def ai_summarize(bullets: list[str]) -> list[str]:
    """Optional AI post-processing.

    Enabled only when OPENAI_API_KEY and OPENAI_MODEL are set.
    If anything fails, returns the original bullets.
    """

    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    model = os.environ.get("OPENAI_MODEL", "").strip()
    if not api_key or not model:
        return bullets

    base_url = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")
    url = f"{base_url}/chat/completions"

    prompt = (
        "Rewrite the following changelog bullets to be concise, user-facing, and non-technical. "
        "Keep 3 to 8 bullets max. Avoid duplicates. Do not invent features. "
        "Return ONLY a JSON array of strings.\n\nBullets:\n"
        + "\n".join(f"- {b}" for b in bullets)
    )

    payload = {
        "model": model,
        "temperature": 0.2,
        "messages": [
            {"role": "system", "content": "You write concise game release notes."},
            {"role": "user", "content": prompt},
        ],
    }

    req = request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with request.urlopen(req, timeout=20) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
        data = json.loads(raw)
        content = data["choices"][0]["message"]["content"]
        out = json.loads(content)
        if not isinstance(out, list) or not all(isinstance(x, str) for x in out):
            return bullets
        cleaned = [normalize_bullet(x) for x in out if normalize_bullet(x)]
        return cleaned[:10] or bullets
    except Exception:
        return bullets


@dataclass(frozen=True)
class Section:
    version: str
    date_utc: str
    bullets: list[str]


def build_section(version: str, base_ref: str | None) -> Section:
    msgs = commits_since(base_ref)
    bullets: list[str] = []
    seen: set[str] = set()
    for m in msgs:
        b = normalize_bullet(m)
        if not b:
            continue
        if b in seen:
            continue
        seen.add(b)
        bullets.append(b)

    # Keep it short and optionally rewrite via AI.
    bullets = bullets[:12]
    bullets = ai_summarize(bullets)
    bullets = bullets[:10]
    if not bullets:
        bullets = ["No notable changes."]

    date_utc = dt.datetime.utcnow().strftime("%Y-%m-%d")
    return Section(version=version, date_utc=date_utc, bullets=bullets)


def render_markdown(sec: Section) -> str:
    lines: list[str] = []
    lines.append(f"## {sec.version} - {sec.date_utc}")
    lines.append("")
    for b in sec.bullets:
        lines.append(f"- {b}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True, help="Version string, e.g. v1.2.3")
    ap.add_argument(
        "--base",
        default="auto",
        help="Base ref to diff from (tag). Use 'auto' to pick last tag, or '' for full history.",
    )
    args = ap.parse_args()

    if not is_git_repo():
        print("ERROR: not a git repo", file=sys.stderr)
        return 2

    base_ref: str | None
    if args.base == "auto":
        base_ref = last_tag() or None
    elif args.base.strip() == "":
        base_ref = None
    else:
        base_ref = args.base

    sec = build_section(args.version, base_ref)
    sys.stdout.write(render_markdown(sec))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
