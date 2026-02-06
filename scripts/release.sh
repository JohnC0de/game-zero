#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GODOT_BIN="${GODOT_BIN:-godot}"

PROJECT_GODOT_BACKUP=""

cleanup() {
	if [[ -n "${PROJECT_GODOT_BACKUP:-}" && -f "$PROJECT_GODOT_BACKUP" ]]; then
		mv -f "$PROJECT_GODOT_BACKUP" "$PROJECT_DIR/project.godot"
	fi
}

trap cleanup EXIT

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "❌ Missing required command: $cmd" >&2
		exit 1
	fi
}

set_project_version_for_export() {
	local version="$1"
	local project_file="$PROJECT_DIR/project.godot"

	if [[ ! -f "$project_file" ]]; then
		return 0
	fi
	if ! command -v python3 >/dev/null 2>&1; then
		# No python3: skip mutation; keep whatever is in project.godot.
		return 0
	fi

	PROJECT_GODOT_BACKUP="$PROJECT_DIR/build/project.godot.bak"
	mkdir -p "$PROJECT_DIR/build"
	cp -a "$project_file" "$PROJECT_GODOT_BACKUP"

	python3 - "$project_file" "$version" <<'PY'
import sys

path = sys.argv[1]
version = sys.argv[2]

with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
in_app = False
found = False
inserted = False

for line in lines:
    stripped = line.strip()
    if stripped.startswith('[') and stripped.endswith(']'):
        if in_app and not found and not inserted:
            out.append(f'config/version="{version}"\n')
            inserted = True
        in_app = (stripped == '[application]')
        out.append(line)
        continue

    if in_app and stripped.startswith('config/version='):
        out.append(f'config/version="{version}"\n')
        found = True
        continue

    if in_app and not found and not inserted and stripped.startswith('run/main_scene='):
        out.append(f'config/version="{version}"\n')
        inserted = True
        out.append(line)
        continue

    out.append(line)

if in_app and not found and not inserted:
    out.append(f'config/version="{version}"\n')

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(out)
PY
}

get_project_name() {
	local name
	name="$(awk -F= '/^config\/name=/{sub(/^"/,"",$2); sub(/"$/,"",$2); print $2; exit}' "$PROJECT_DIR/project.godot")"
	if [[ -z "${name:-}" ]]; then
		echo "game"
		return 0
	fi
	echo "$name"
}

slugify() {
	# Lowercase, replace spaces with underscores, drop other characters.
	echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-z0-9_'
}

build_id() {
	if ! command -v git >/dev/null 2>&1; then
		return 0
	fi
	if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		return 0
	fi

	# Prefer a clean, exact tag (e.g. v1.2.3) for stable artifact naming.
	local tag
	tag="$(git -C "$PROJECT_DIR" describe --tags --exact-match 2>/dev/null || true)"
	if [[ -n "${tag:-}" ]]; then
		local dirty=""
		if ! git -C "$PROJECT_DIR" diff --quiet >/dev/null 2>&1 || ! git -C "$PROJECT_DIR" diff --cached --quiet >/dev/null 2>&1; then
			dirty="-dirty"
		fi
		echo "${tag}${dirty}"
		return 0
	fi

	# Not on a tag: use commit SHA (no timestamps) so local builds remain unique.
	local sha
	sha="$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
	if [[ -n "${sha:-}" ]]; then
		local dirty2=""
		if ! git -C "$PROJECT_DIR" diff --quiet >/dev/null 2>&1 || ! git -C "$PROJECT_DIR" diff --cached --quiet >/dev/null 2>&1; then
			dirty2="-dirty"
		fi
		echo "dev-${sha}${dirty2}"
		return 0
	fi
}

sanitize_id() {
	# Keep filenames portable across platforms.
	# Allowed: A-Z a-z 0-9 . _ + -
	echo "$1" | tr -cd 'A-Za-z0-9._+-'
}

package_dir() {
	local src_dir="$1"
	local out_file="$2"
	local name="$3"
	local tmp_dir

	tmp_dir="$(mktemp -d)"
	trap "rm -rf \"$tmp_dir\"" RETURN

	local stage="$tmp_dir/$name"
	mkdir -p "$stage"
	cp -a "$src_dir"/. "$stage"/

	if command -v zip >/dev/null 2>&1; then
		(cd "$tmp_dir" && zip -qr "$out_file" "$name")
		return 0
	fi

	if command -v tar >/dev/null 2>&1; then
		# Fallback if zip isn't installed.
		tar -C "$tmp_dir" -czf "$out_file" "$name"
		return 0
	fi

	echo "❌ Need zip or tar to package builds" >&2
	exit 1
}

run_export() {
	local preset="$1"
	local out_path="$2"
	local log_file="$3"
	local export_flags

	# Allow CI to override display/rendering settings for stability.
	# Default remains headless so local automation works without a window server.
	export_flags="${GODOT_EXPORT_FLAGS:---headless}"

	echo "=== Exporting: $preset ==="
	echo "[export] preset=$preset out=$out_path" >>"$log_file"

	# shellcheck disable=SC2086
	if ! "$GODOT_BIN" $export_flags --path "$PROJECT_DIR" --export-release "$preset" "$out_path" >>"$log_file" 2>&1; then
		echo "❌ Export failed for preset '$preset'" >&2
		echo "--- Last 80 log lines ($log_file) ---" >&2
		tail -n 80 "$log_file" >&2 || true
		exit 1
	fi
}

make_linux_appimage() {
	local linux_dir="$1"
	local slug="$2"
	local app_name="$3"
	local id_safe="$4"
	local dist_dir="$5"
	local build_root="$6"

	local out_appimage="$dist_dir/${slug}_${id_safe}_linux_x86_64.AppImage"
	chmod +x "$SCRIPT_DIR/make_appimage.sh"
	"$SCRIPT_DIR/make_appimage.sh" "$linux_dir" "$slug" "$app_name" "$id_safe" "$out_appimage" "$build_root"
	echo "$out_appimage"
}

main() {
	require_cmd "$GODOT_BIN"

	# 1) Bootstrap (templates + optional lint tooling)
	"$SCRIPT_DIR/bootstrap_build.sh"

	# 2) Validate project (compile + lint + unit tests)
	"$SCRIPT_DIR/validate.sh"

	local name slug id
	name="$(get_project_name)"
	slug="$(slugify "$name")"
	if [[ -z "${slug:-}" ]]; then
		slug="game"
	fi

	id="$(build_id)"
	if [[ -z "${id:-}" ]]; then
		# Fallback when git isn't available: keep old behavior.
		id="$(date +%Y%m%d_%H%M%S)"
	fi
	local id_safe
	id_safe="$(sanitize_id "$id")"
	if [[ -z "${id_safe:-}" ]]; then
		id_safe="$(date +%Y%m%d_%H%M%S)"
	fi

	# Ensure exported builds embed the same version we are releasing.
	# This lets the game compare its current version with GitHub tags reliably.
	set_project_version_for_export "$id"

	local build_root="$PROJECT_DIR/build/releases/$id_safe"
	local dist_dir="$PROJECT_DIR/dist"
	local linux_dir="$build_root/linux"
	local windows_dir="$build_root/windows"
	local export_log="$build_root/export.log"

	mkdir -p "$linux_dir" "$windows_dir" "$dist_dir"

	# Cleanup old staging directories accidentally created in dist/ by older scripts.
	if [[ -d "$dist_dir/.tools" ]]; then
		rm -rf "$dist_dir/.tools"
	fi
	for d in "$dist_dir"/*.AppDir; do
		if [[ -d "$d" ]]; then
			rm -rf "$d"
		fi
	done
	: >"$export_log"

	# 3) Export binaries
	run_export "Linux" "$linux_dir/${slug}.x86_64" "$export_log"
	chmod +x "$linux_dir/${slug}.x86_64" || true

	run_export "Windows Desktop" "$windows_dir/${slug}.exe" "$export_log"

	# 4) Package artifacts
	local linux_pkg_root="${slug}_${id_safe}_linux_x86_64"
	local win_pkg_root="${slug}_${id_safe}_windows_x86_64"

	local linux_archive="$dist_dir/${linux_pkg_root}.zip"
	local win_archive="$dist_dir/${win_pkg_root}.zip"

	if ! command -v zip >/dev/null 2>&1; then
		linux_archive="$dist_dir/${linux_pkg_root}.tar.gz"
		win_archive="$dist_dir/${win_pkg_root}.tar.gz"
	fi

	package_dir "$linux_dir" "$linux_archive" "$linux_pkg_root"
	package_dir "$windows_dir" "$win_archive" "$win_pkg_root"

	# 4b) Linux AppImage (in addition to the zip)
	local appimage_path
	appimage_path="$(make_linux_appimage "$linux_dir" "$slug" "$name" "$id_safe" "$dist_dir" "$build_root")"

	# 5) Checksums
	(
		cd "$dist_dir" || exit 1
		sha256sum "$(basename "$linux_archive")" "$(basename "$win_archive")" "$(basename "$appimage_path")" >SHA256SUMS.txt
	)

	# 6) Build info
	cat >"$dist_dir/BUILD_INFO.txt" <<EOF
project_name=$name
slug=$slug
build_id=$id
build_id_safe=$id_safe
godot_version=$($GODOT_BIN --version | head -n 1)
date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

	# Optional: release notes for GitHub Releases.
	# Only write RELEASE_NOTES.md for clean semver tags (e.g. v1.2.3).
	# This file is committed by scripts/release_version.sh and should not be overwritten
	# by ad-hoc local builds like "v0.1.0-dirty".
	if [[ "$id" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] && command -v python3 >/dev/null 2>&1 && [[ -f "$PROJECT_DIR/CHANGELOG.md" ]]; then
		python3 "$SCRIPT_DIR/extract_release_notes.py" --version "$id" --out "$dist_dir/RELEASE_NOTES.md" || true
	fi

	echo "✅ Done"
	echo "   Linux:   $linux_archive"
	echo "   Windows: $win_archive"
	echo "   Checks:  $dist_dir/SHA256SUMS.txt"
}

main "$@"
