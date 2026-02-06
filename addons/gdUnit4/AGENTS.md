# addons/gdUnit4/

Vendored gdUnit4 framework (do not treat as project source code).

## Where It Is Used

- `scripts/validate.sh` runs: `addons/gdUnit4/bin/GdUnitCmdTool.gd` against `test/unit/`.
- `project.godot` enables the plugin and configures strict warning rules for `res://addons/gdUnit4`.

## Conventions

- Avoid editing vendored files unless you are deliberately patching/upgrading gdUnit4.
- If tests fail inside gdUnit4 internals, first verify project configuration (autoloads, warning rules, test paths).
