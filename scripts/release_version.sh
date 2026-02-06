#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
	cat <<EOF
Usage:
  $0 patch|minor|major
  $0 vX.Y.Z

Behavior:
  - Runs ./scripts/validate.sh
  - Generates a new CHANGELOG.md section
  - Updates project.godot config/version
  - Creates a release commit + tag

Environment:
  - Set PUSH=1 to push commit+tag.
EOF
}

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "❌ Missing required command: $cmd" >&2
		exit 1
	fi
}

is_git_repo() {
	git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

last_tag() {
	git -C "$PROJECT_DIR" describe --tags --abbrev=0 2>/dev/null || true
}

strip_v() {
	local v="$1"
	if [[ "$v" == v* || "$v" == V* ]]; then
		echo "${v:1}"
		return 0
	fi
	echo "$v"
}

bump_version() {
	local current="$1"
	local bump="$2"

	local base
	base="$(strip_v "$current")"
	IFS='.' read -r major minor patch <<<"$base"
	major="${major:-0}"
	minor="${minor:-0}"
	patch="${patch:-0}"

	case "$bump" in
	major)
		major=$((major + 1))
		minor=0
		patch=0
		;;
	minor)
		minor=$((minor + 1))
		patch=0
		;;
	patch)
		patch=$((patch + 1))
		;;
	*)
		echo "❌ Unknown bump: $bump" >&2
		exit 2
		;;
	esac

	echo "v${major}.${minor}.${patch}"
}

ensure_clean_tree() {
	if [[ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]]; then
		echo "❌ Git working tree is dirty. Commit/stash changes before releasing." >&2
		exit 1
	fi
}

prepend_changelog_section() {
	local version="$1"
	local section
	section="$(python3 "$SCRIPT_DIR/generate_changelog.py" --version "$version")"

	local file="$PROJECT_DIR/CHANGELOG.md"
	if [[ ! -f "$file" ]]; then
		echo "❌ Missing CHANGELOG.md" >&2
		exit 1
	fi

	python3 - "$file" "$section" <<'PY'
import sys

path = sys.argv[1]
section = sys.argv[2]

with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

marker = "## Unreleased\n"
idx = text.find(marker)
if idx == -1:
    raise SystemExit("CHANGELOG.md missing '## Unreleased'")

insert_at = idx + len(marker)
new_text = text[:insert_at] + "\n" + section + "\n" + text[insert_at:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_text)
PY
}

main() {
	if [[ $# -ne 1 ]]; then
		usage
		exit 2
	fi

	require_cmd git
	require_cmd python3

	if ! is_git_repo; then
		echo "❌ This project is not a git repo; release automation requires git." >&2
		exit 1
	fi

	local arg="$1"
	local prev_tag
	prev_tag="$(last_tag)"
	if [[ -z "${prev_tag:-}" ]]; then
		prev_tag="v0.0.0"
	fi

	local version
	if [[ "$arg" == v* || "$arg" == V* ]]; then
		version="$arg"
	else
		version="$(bump_version "$prev_tag" "$arg")"
	fi

	ensure_clean_tree

	# Validate first
	"$SCRIPT_DIR/validate.sh"

	# Changelog + project version
	prepend_changelog_section "$version"
	python3 "$SCRIPT_DIR/update_project_version.py" --project "$PROJECT_DIR/project.godot" --version "$version"

	# Release notes output used by CI
	python3 "$SCRIPT_DIR/extract_release_notes.py" --version "$version" --out "$PROJECT_DIR/dist/RELEASE_NOTES.md"

	# Commit + tag
	git -C "$PROJECT_DIR" add CHANGELOG.md project.godot dist/RELEASE_NOTES.md
	git -C "$PROJECT_DIR" commit -m "release: $version"
	git -C "$PROJECT_DIR" tag "$version"

	if [[ "${PUSH:-0}" == "1" ]]; then
		git -C "$PROJECT_DIR" push
		git -C "$PROJECT_DIR" push --tags
	fi

	echo "✅ Release prepared: $version"
	echo "   Next: push tags to trigger CI build/release."
}

main "$@"
