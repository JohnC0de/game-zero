#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/.venv"
GODOT_BIN="${GODOT_BIN:-godot}"

echo "=== Validating Godot Project ==="

# Step 1: Compilation check using editor mode (doesn't run the game)
echo "[1/3] Checking compilation..."
COMPILE_OUTPUT=$("$GODOT_BIN" --headless --path "$PROJECT_DIR" --editor --quit 2>&1 || true)
if echo "$COMPILE_OUTPUT" | grep -qiE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script"; then
	echo "$COMPILE_OUTPUT" | grep -iE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load|warning treated"
	echo "❌ Compilation errors found!"
	exit 1
fi
echo "✅ Compilation OK"

# Step 2: GDScript linter (gdtoolkit)
echo "[2/3] Running gdlint..."
if [ -d "$VENV_DIR" ]; then
	if ! "$VENV_DIR/bin/gdlint" "$PROJECT_DIR"/src/**/*.gd 2>&1; then
		echo "❌ Lint errors found!"
		exit 1
	fi
	echo "✅ Lint OK"
else
	echo "⚠️  Skipping lint (.venv not found)"
	echo "   Setup: python -m venv .venv && .venv/bin/pip install gdtoolkit"
fi

# Step 3: Unit tests (gdUnit4) with timeout
echo "[3/3] Running unit tests..."

TEST_EXIT=0
TEST_OUTPUT=$(timeout 60 "$GODOT_BIN" --headless --path "$PROJECT_DIR" -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
	-a test/unit --ignoreHeadlessMode 2>&1) || TEST_EXIT=$?

echo "$TEST_OUTPUT"

if [ $TEST_EXIT -eq 124 ]; then
	echo "❌ Tests timed out!"
	exit 1
fi

if echo "$TEST_OUTPUT" | grep -qE "FAILED|errors: [1-9]|failures: [1-9]"; then
	echo "❌ Tests failed!"
	exit 1
fi

echo "✅ Tests passed"
echo "=== Validation Complete ==="
