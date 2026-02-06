# test/

Project tests.

## Where To Look

- `test/unit/` contains gdUnit4 suites (mainly what `scripts/validate.sh` runs).
- `test/test_runner.gd` is a lightweight SceneTree-based runner (not the default in CI).

## Commands

```bash
# Run all unit tests (gdUnit4)
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit --ignoreHeadlessMode

# Run a single suite file
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a test/unit/test_game_logic.gd --ignoreHeadlessMode
```

## Notes

- Reports are generated under `reports/` (generated output).
