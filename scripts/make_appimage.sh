#!/usr/bin/env bash
set -euo pipefail

# Creates a Linux x86_64 AppImage from a Godot export output directory.
# Input dir must contain:
# - <slug>.x86_64 (executable)
# - <slug>.pck

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

ensure_appimagetool() {
	local work_dir="$1"
	local tool_dir="$work_dir/.tools"
	mkdir -p "$tool_dir"

	local tool_appimage="$tool_dir/appimagetool-x86_64.AppImage"
	local extracted_dir="$tool_dir/appimagetool.squashfs"

	if [[ ! -x "$tool_appimage" ]]; then
		require_cmd chmod
		echo "Downloading appimagetool" >&2
		download_file "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" "$tool_appimage"
		chmod +x "$tool_appimage"
	fi

	if [[ ! -x "$extracted_dir/AppRun" ]]; then
		require_cmd rm
		require_cmd mkdir
		require_cmd chmod
		echo "Extracting appimagetool (avoid FUSE requirement)" >&2
		rm -rf "$extracted_dir"
		(
			cd "$tool_dir"
			./appimagetool-x86_64.AppImage --appimage-extract >/dev/null
			mv squashfs-root "$(basename "$extracted_dir")"
		)
		chmod +x "$extracted_dir/AppRun"
	fi

	echo "$extracted_dir/AppRun"
}

main() {
	if [[ $# -ne 6 ]]; then
		echo "Usage: $0 <export_dir> <slug> <app_name> <version> <out_appimage> <work_dir>" >&2
		exit 2
	fi

	local export_dir="$1"
	local slug="$2"
	local app_name="$3"
	local version="$4"
	local out_appimage="$5"
	local work_dir="$6"

	require_cmd mkdir
	require_cmd cp
	require_cmd chmod

	local exe_src="$export_dir/${slug}.x86_64"
	local pck_src="$export_dir/${slug}.pck"
	if [[ ! -f "$exe_src" || ! -f "$pck_src" ]]; then
		echo "❌ Export dir missing expected files: $exe_src and/or $pck_src" >&2
		exit 1
	fi

	mkdir -p "$work_dir"
	mkdir -p "$(dirname "$out_appimage")"

	local appdir="$work_dir/appimage/${slug}.AppDir"
	rm -rf "$appdir"
	mkdir -p "$appdir/usr/bin"

	# Put executable + pck next to each other.
	cp -a "$exe_src" "$appdir/usr/bin/${slug}.x86_64"
	cp -a "$pck_src" "$appdir/usr/bin/${slug}.pck"
	chmod +x "$appdir/usr/bin/${slug}.x86_64"

	# Desktop entry (AppImageKit looks for *.desktop in AppDir root).
	cat >"$appdir/${slug}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${app_name}
Exec=${slug}.x86_64
Icon=${slug}
Categories=Game;
Terminal=false
EOF

	# Icon: keep SVG (no extra deps). AppImageKit accepts SVG in practice.
	if [[ -f "$PROJECT_DIR/icon.svg" ]]; then
		cp -a "$PROJECT_DIR/icon.svg" "$appdir/${slug}.svg"
	fi

	# AppRun: just exec the Godot binary.
	cat >"$appdir/AppRun" <<'EOF'
#!/bin/sh
set -eu
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/APP_SLUG.x86_64" "$@"
EOF
	sed -i "s/APP_SLUG/${slug}/g" "$appdir/AppRun"
	chmod +x "$appdir/AppRun"

	# Build AppImage.
	local appimagetool
	appimagetool="$(ensure_appimagetool "$work_dir")"

	ARCH=x86_64 "$appimagetool" "$appdir" "$out_appimage" >/dev/null

	if [[ ! -f "$out_appimage" ]]; then
		echo "❌ AppImage build failed: $out_appimage not created" >&2
		exit 1
	fi

	echo "✅ AppImage created: $out_appimage"
}

main "$@"
