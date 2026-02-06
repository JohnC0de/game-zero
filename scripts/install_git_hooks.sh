#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --git-dir >/dev/null 2>&1; then
	echo "Not a git repository. Run: git init"
	exit 1
fi

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit

echo "Installed git hooks via core.hooksPath=.githooks"
echo "To skip validation on a commit: SKIP_GODOT_VALIDATE=1 git commit ..."
