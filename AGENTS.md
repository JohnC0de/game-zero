# AGENTS.md

Instructions for AI agents working on this Godot project.

## Project Map (Repository Navigation)

Neon Survivor (Godot 4.6). The game boots via `project.godot` -> `run/main_scene`, then loads `world.tscn` for gameplay.

```text
./
├── project.godot              # main scene, autoloads, strict GDScript warnings
├── world.tscn                 # gameplay scene (loaded from main menu)
├── src/                       # game code (entities/systems/ui/autoloads)
├── test/                      # gdUnit4 unit tests + local runner
├── scripts/                   # validate/build/release automation
├── addons/gdUnit4/            # vendored test framework (avoid editing)
├── build/                     # local export outputs (generated)
├── dist/                      # packaged archives + checksums (generated)
└── reports/                   # gdUnit4 HTML/XML reports (generated)
```

Where to look (common tasks):

| Task | Location |
|------|----------|
| Change main menu / start flow | `src/ui/main_menu.gd`, `src/ui/main_menu.tscn`, `world.tscn` |
| Game state (pause/level-up/game-over) | `src/autoloads/game.gd` |
| Event bus (signals between systems/UI) | `src/autoloads/events.gd` |
| Balance knobs (XP/spawns/scaling/player) | `src/systems/balance/`, `src/autoloads/balance.gd`, `docs/balance.md` |
| Spawning + adaptive difficulty | `src/systems/wave_spawner.gd`, `src/systems/balance/encounter_director.gd` |
| Upgrades + stat modifiers | `src/systems/upgrade_manager.gd`, `src/systems/upgrades/`, `src/autoloads/stats.gd` |
| Unit tests | `test/unit/`, `scripts/validate.sh` |
| Build + package releases | `scripts/release.sh`, `.github/workflows/release.yml` |

## Releases & Changelog (Required)

This project ships updates via GitHub Releases and supports in-game update prompts.

- Current version is stored in `project.godot` under `[application]` as `config/version`.
- Release notes live in `CHANGELOG.md`.
- Preferred workflow for a versioned release (commit + tag): `scripts/release_version.sh`.
- CI builds and publishes artifacts on tag push via `.github/workflows/release.yml`.

When assisting with shipping/release work, ALWAYS ensure:
- `CHANGELOG.md` is updated for the new version
- `project.godot` has the same `config/version` as the tag (e.g. `v1.2.3`)

### Release Commands (Canonical)

```bash
# Build + package (bootstrap + validate + export + checksums)
./scripts/release.sh

# Create a versioned release (validate + changelog + version bump + commit + tag)
./scripts/release_version.sh patch
./scripts/release_version.sh minor
./scripts/release_version.sh major

# Or set an explicit version
./scripts/release_version.sh v1.2.3

# Push automatically (commit + tag), triggering CI publish
PUSH=1 ./scripts/release_version.sh patch
```

Notes:

- `scripts/release_version.sh` requires a clean git working tree.
- `scripts/release.sh` respects `GODOT_BIN` (defaults to `godot`) and `GODOT_EXPORT_FLAGS` (defaults to `--headless`).
- CI runs `./scripts/release.sh` with `GODOT_BIN=./scripts/godot_xvfb.sh` and a dummy renderer for stability (see `.github/workflows/release.yml`).

### Changelog Automation

- `CHANGELOG.md` is the source of release notes.
- `scripts/release_version.sh` inserts a new section under `## Unreleased`.
- The changelog section is generated from `git log` messages via `scripts/generate_changelog.py`.
- Optional AI rewrite is supported when env vars are present:
  - `OPENAI_API_KEY` (required)
  - `OPENAI_MODEL` (required)
  - `OPENAI_BASE_URL` (optional; defaults to `https://api.openai.com/v1`)
  - If AI fails/unset, the script falls back to deterministic bullets.

### GitHub Release Notes

- CI extracts the current version notes into `dist/RELEASE_NOTES.md` using `scripts/extract_release_notes.py`.
- `.github/workflows/release.yml` publishes a GitHub Release on tag push (`v*`) and uses `body_path: dist/RELEASE_NOTES.md`.

Tip:

- `scripts/release_version.sh` also writes `dist/RELEASE_NOTES.md` and commits it, so the exact notes used by CI are reviewable.

### In-Game Updates (GitHub Only)

This repo supports in-game update prompts driven by GitHub Releases.

Configuration (in `project.godot` `[application]`):

- `config/version="vX.Y.Z"` (must match the git tag used for releases)
- `config/update_owner="<github-user-or-org>"`
- `config/update_repo="<repo-name>"`

Runtime behavior:

- `UpdateManager` (`src/autoloads/update_manager.gd`) calls GitHub `releases/latest`.
- The UI shows current version in:
  - `src/ui/main_menu.tscn`
  - `src/ui/pause_menu.tscn`
  - `src/ui/game_over.tscn`
- When an update exists, main menu shows `New version` + `Current` and offers `DOWNLOAD & RESTART`.

Release asset requirements (must be attached to the GitHub Release):

- `SHA256SUMS.txt`
- `*_windows_x86_64.zip`
- `*_linux_x86_64.AppImage` (preferred) or fallback `*_linux_x86_64.zip`

Asset selection rules:

- `UpdateManager` selects assets by filename suffix (not by exact project name).
- Linux prefers `*_linux_x86_64.AppImage` when present.

Notes:

- `scripts/release.sh` temporarily sets `config/version` during export to match the build id (tag/sha) and restores `project.godot` afterwards.
- Updates can fail if the install directory is not writable (Windows Program Files, locked folders).
- Version comparison is semantic-ish: `v` prefix is ignored and any `-suffix` (e.g. `-rc.1`) is ignored; only the first 3 numeric components are compared.
- More detail: `docs/updates.md`.

## Memory: Learn From Past Mistakes (MANDATORY)

**Before implementing**: Check `memory.md` for relevant pitfalls in the area you're working on.

**After fixing a bug**: Add an entry to `memory.md` with:
- Date, symptom, root cause, fix, affected files
- Code snippet showing the correct pattern

This prevents repeating the same mistakes. The file is organized by category (UI, GDScript patterns, Godot gotchas, etc.).

## Tmux Session Convention

Multiple AI agents may work on different Godot projects simultaneously. Use this naming convention:

| Resource | Pattern | Example |
|----------|---------|---------|
| Session name | `godot-{project}` | `godot-game-zero` |
| Log file | `/tmp/godot-{project}.log` | `/tmp/godot-game-zero.log` |

**For this project**: session = `godot-game-zero`, log = `/tmp/godot-game-zero.log`

### Session Workflow (ALWAYS follow this order)

```bash
# 1. FIRST: Check if session exists
tmux has-session -t godot-game-zero 2>/dev/null && echo "EXISTS" || echo "NOT_FOUND"

# 2. IF NOT_FOUND: Create and start editor
tmux new-session -d -s godot-game-zero
tmux send-keys -t godot-game-zero "godot --editor --path $(pwd) --verbose 2>&1 | tee /tmp/godot-game-zero.log" Enter

# 3. IF EXISTS: Check if editor is actually running (session might be empty/crashed)
tmux capture-pane -t godot-game-zero -p | tail -5
```

### One-liner: Ensure Editor Running

```bash
# Idempotent - safe to run multiple times
tmux has-session -t godot-game-zero 2>/dev/null || (tmux new-session -d -s godot-game-zero && tmux send-keys -t godot-game-zero "godot --editor --path $(pwd) --verbose 2>&1 | tee /tmp/godot-game-zero.log" Enter)
```

### Monitor Logs

```bash
# Stream logs live
tail -f /tmp/godot-game-zero.log

# Search for errors
grep -i error /tmp/godot-game-zero.log
```

### Session Operations

```bash
# List all godot sessions (useful to see what's running)
tmux list-sessions 2>/dev/null | grep "^godot-" || echo "No godot sessions"

# Kill this project's session
tmux kill-session -t godot-game-zero

# Kill ALL godot sessions (use with caution)
tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^godot-" | xargs -I {} tmux kill-session -t {}
```

## Script Validation (MUST RUN AFTER CHANGES)

```bash
# Full validation (compilation + lint + tests) - ALWAYS USE THIS
./scripts/validate.sh

# Quick compilation check only
godot --headless --quit 2>&1 | grep -iE "error|failed" && echo "ERRORS FOUND" || echo "OK"
```

**IMPORTANT**: Always run `./scripts/validate.sh` after modifying `.gd` files before telling the user code is ready.

## Balance & Game Design Systems

PRIORITY RULE: From this point forward, any change that affects gameplay numbers MUST be implemented as a reusable, data-driven system.

- DO NOT hard-code balance numbers inside gameplay logic (spawners, weapons, entities, UI).
- DO create/extend a system/resource when a feature will be reused now or likely reused later.
- DO add/adjust tests for new pacing/selection logic.
- DO document where the knobs live (keep `docs/balance.md` current).

Single sources of truth:

- XP curve: `Balance.get_xp_for_level()` via `src/autoloads/balance.gd`
- Spawning + scaling: `WaveSpawner` reads `Balance` and `EncounterDirector`
- Upgrades: `UpgradeData` + `UpgradeCatalog`, selected via `WeightedPicker`
- Modifiers: `Stats` autoload; upgrades apply to `Stats` (weapons read it)

Docs: `docs/balance.md`

Quick checklist for new balance work:

- New number? Put it in `src/systems/balance/*` (or an `UpgradeData` in `UpgradeCatalog`).
- New upgrade? Add to `src/systems/upgrades/upgrade_catalog.gd` and make it apply via `Stats`.
- New pacing rule? Add a test in `test/unit/` and run `./scripts/validate.sh`.

## GDScript Linter (gdtoolkit)

This project uses [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) for linting and formatting.

### Setup (one-time)

```bash
python -m venv .venv
.venv/bin/pip install gdtoolkit
```

### Commands

```bash
# Lint all files (runs automatically in validate.sh)
.venv/bin/gdlint src/**/*.gd

# Format all files (auto-fix style issues)
.venv/bin/gdformat src/**/*.gd

# Check syntax only
.venv/bin/gdparse src/**/*.gd
```

### Configuration

Lint rules are configured in `.gdlintrc`. Current disabled rules:
- `class-definitions-order` - We allow `class_name` after `extends`
- `no-else-return`, `no-elif-return` - Early returns with else allowed for clarity
- `max-returns` - Switch-like functions may have many returns

### Lint Rules to Follow

```gdscript
# Prefix unused arguments with underscore
func _on_signal(_unused_arg: int) -> void:
    pass

# Avoid trailing whitespace (gdformat fixes this)

# Keep lines under 120 characters
```

**ENFORCEMENT**: The validation script fails if lint errors exist. Fix all lint issues before completing work.

## gdUnit4 Testing Framework

This project uses [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) v6.1.1 for unit testing.

### Running Tests

```bash
# Run all tests (used by validate.sh)
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit --ignoreHeadlessMode

# Run specific test file
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/test_game_logic.gd --ignoreHeadlessMode

# Continue on failure (run all tests even if some fail)
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit --ignoreHeadlessMode -c
```

### Writing Tests

Tests live in `test/unit/` and extend `GdUnitTestSuite`:

```gdscript
extends GdUnitTestSuite

func test_example() -> void:
    assert_int(Game.get_xp_for_level(1)).is_equal(10)

func test_comparison() -> void:
    assert_int(value).is_greater(0)
    assert_str(name).is_not_empty()
    assert_bool(flag).is_true()
```

### Test Reports

After running tests, HTML/XML reports are generated in `reports/` directory.

## GDScript Typing Rules (MANDATORY)

**Full static typing is required.** Every variable, parameter, and return type must be explicitly typed.

### Rules

| Element | Requirement | Example |
|---------|-------------|---------|
| Variables | Explicit type | `var speed: float = 10.0` |
| Constants | Explicit type | `const MAX_HP: int = 100` |
| Function params | All typed | `func deal_damage(amount: int, source: Node2D)` |
| Return types | Always declared | `func get_name() -> String:` |
| Signals | Typed parameters | `signal hit(damage: int, attacker: Node2D)` |
| Arrays | Typed when possible | `var enemies: Array[Node2D] = []` |

### Avoid Variant Inference

```gdscript
# BAD - infers Variant
var time := stats.get("time", 0.0)

# GOOD - use 'as' cast (int()/float() don't accept Variant)
var time: float = stats.get("time", 0.0) as float

# BAD - returns Variant
var enemy := area.get_parent()

# GOOD - explicit cast
var enemy: Node2D = area.get_parent() as Node2D
```

### Dictionary/JSON Values

Dictionary access returns Variant. Use `as` cast, not constructors:

```gdscript
# BAD - int() rejects Variant with strict settings
var kills: int = int(dict.get("kills", 0))

# GOOD - 'as' cast works with Variant
var kills: int = dict.get("kills", 0) as int
```

### Void Functions

Always declare `-> void` for functions that don't return a value:

```gdscript
# BAD
func _ready():
    pass

# GOOD
func _ready() -> void:
    pass

# Lambdas too:
signal.connect(func() -> void: do_thing())
```

### For Loop Iterators

All for loop variables must have explicit types:

```gdscript
# BAD
for child in get_children():
for i in count:

# GOOD
for child: Node in get_children():
for i: int in count:
```

**ENFORCEMENT**: Code review will reject untyped code. No exceptions.

## Quick Reference

| Task | Command |
|------|---------|
| Full validation | `./scripts/validate.sh` |
| Validate scripts | `godot --headless --quit 2>&1 \| grep -iE "error\|failed"` |
| Run tests | `godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit --ignoreHeadlessMode` |
| Start editor | `tmux has-session -t godot-game-zero 2>/dev/null \|\| (tmux new-session -d -s godot-game-zero && tmux send-keys -t godot-game-zero "godot --editor --path $(pwd) --verbose 2>&1 \| tee /tmp/godot-game-zero.log" Enter)` |
| View logs | `tail -f /tmp/godot-game-zero.log` |
| Stop editor | `tmux kill-session -t godot-game-zero` |
| Lint all files | `.venv/bin/gdlint src/**/*.gd` |
| Format all files | `.venv/bin/gdformat src/**/*.gd` |
