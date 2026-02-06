#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

GODOT_BIN="${GODOT_BIN:-godot}"

require_cmd() {
	local cmd="$1"
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "❌ Missing required command: $cmd" >&2
		exit 1
	fi
}

download_file() {
	local url="$1"
	local out="$2"

	if command -v curl >/dev/null 2>&1; then
		curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"
		return 0
	fi

	if command -v wget >/dev/null 2>&1; then
		wget -O "$out" "$url"
		return 0
	fi

	echo "❌ Need curl or wget to download files" >&2
	exit 1
}

get_template_version() {
	local version_str
	version_str="$($GODOT_BIN --version | tr -d '\r' | head -n 1)"

	# Examples:
	# - 4.6.stable.arch_linux
	# - 4.6.stable.official.89cea143
	# We want: 4.6.stable
	local major minor channel rest
	IFS='.' read -r major minor channel rest <<<"$version_str"
	if [[ -z "${major:-}" || -z "${minor:-}" || -z "${channel:-}" ]]; then
		echo "❌ Unable to parse Godot version: '$version_str'" >&2
		exit 1
	fi
	echo "${major}.${minor}.${channel}"
}

ensure_export_templates() {
	require_cmd unzip

	local template_version
	template_version="$(get_template_version)"
	local templates_dir="$HOME/.local/share/godot/export_templates/${template_version}"

	local need_install="0"
	if [[ ! -d "$templates_dir" ]]; then
		need_install="1"
	fi

	# Godot expects templates directly under the version directory, e.g.
	# ~/.local/share/godot/export_templates/4.6.stable/linux_release.x86_64
	# Some template archives unzip into a nested "templates/" directory.
	local nested_dir="$templates_dir/templates"
	if [[ -d "$nested_dir" ]] && ! ls "$templates_dir"/linux_release* >/dev/null 2>&1; then
		echo "🔧 Normalizing templates directory layout (moving files from templates/ to root)"
		for f in "$nested_dir"/*; do
			local base
			base="$(basename "$f")"
			if [[ ! -e "$templates_dir/$base" ]]; then
				mv "$f" "$templates_dir/"
			fi
		done
		rmdir "$nested_dir" 2>/dev/null || true
	fi

	if [[ "$need_install" == "0" ]] && ls "$templates_dir"/linux_release* >/dev/null 2>&1 && ls "$templates_dir"/windows_release* >/dev/null 2>&1; then
		echo "✅ Export templates already installed: $templates_dir"
		return 0
	fi

	local major minor channel
	IFS='.' read -r major minor channel <<<"$template_version"
	local tag="${major}.${minor}-${channel}"
	local asset="Godot_v${major}.${minor}-${channel}_export_templates.tpz"
	local url="https://github.com/godotengine/godot/releases/download/${tag}/${asset}"

	echo "⬇️  Installing export templates for Godot ${template_version}"
	echo "   URL: $url"

	mkdir -p "$templates_dir"

	local tmp_dir
	tmp_dir="$(mktemp -d)"
	trap "rm -rf \"$tmp_dir\"" RETURN

	local tpz="$tmp_dir/$asset"
	download_file "$url" "$tpz"
	unzip -q "$tpz" -d "$templates_dir"

	# Normalize layout if archive extracted under templates/.
	nested_dir="$templates_dir/templates"
	if [[ -d "$nested_dir" ]] && ! ls "$templates_dir"/linux_release* >/dev/null 2>&1; then
		for f in "$nested_dir"/*; do
			local base
			base="$(basename "$f")"
			if [[ ! -e "$templates_dir/$base" ]]; then
				mv "$f" "$templates_dir/"
			fi
		done
		rmdir "$nested_dir" 2>/dev/null || true
	fi

	if ! ls "$templates_dir"/linux_release* >/dev/null 2>&1; then
		echo "❌ Templates install seems incomplete (missing linux_release*) in $templates_dir" >&2
		exit 1
	fi
	if ! ls "$templates_dir"/windows_release* >/dev/null 2>&1; then
		echo "❌ Templates install seems incomplete (missing windows_release*) in $templates_dir" >&2
		exit 1
	fi

	echo "✅ Export templates installed: $templates_dir"
}

ensure_gdtoolkit() {
	# Optional but recommended: enables gdlint in scripts/validate.sh.
	local venv_dir="$PROJECT_DIR/.venv"
	if [[ -x "$venv_dir/bin/gdlint" ]]; then
		echo "✅ gdtoolkit already available: $venv_dir/bin/gdlint"
		return 0
	fi

	if ! command -v python3 >/dev/null 2>&1; then
		echo "⚠️  python3 not found; skipping gdtoolkit install (lint will be skipped)" >&2
		return 0
	fi

	echo "⬇️  Setting up gdtoolkit (optional lint)"
	python3 -m venv "$venv_dir"
	"$venv_dir/bin/pip" install -q --upgrade pip
	"$venv_dir/bin/pip" install -q gdtoolkit

	if [[ -x "$venv_dir/bin/gdlint" ]]; then
		echo "✅ gdtoolkit installed"
	else
		echo "⚠️  gdtoolkit install did not produce gdlint; lint may be skipped" >&2
	fi
}

main() {
	require_cmd "$GODOT_BIN"
	ensure_export_templates
	ensure_gdtoolkit
}

main "$@"
