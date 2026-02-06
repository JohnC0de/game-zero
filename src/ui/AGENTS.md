# src/ui/

User interface scenes and scripts.

## Where To Look

| Screen | Location | Notes |
|--------|----------|-------|
| Main menu | `src/ui/main_menu.tscn`, `src/ui/main_menu.gd` | start loads `res://world.tscn` |
| HUD | `src/ui/hud.tscn`, `src/ui/hud.gd` | listens to `Events.*` |
| Level-up | `src/ui/level_up_ui.tscn`, `src/ui/level_up_ui.gd` | must accept input while paused |
| Game over | `src/ui/game_over.tscn`, `src/ui/game_over.gd` | tree is paused in GAME_OVER |

## Conventions

- If UI must work while paused, set `process_mode = Node.PROCESS_MODE_ALWAYS` in `_ready()` (see `memory.md`).
- Prefer listening to `Events` signals over polling state.

## UI Architecture (Required)

- Use `UIFx` (`src/ui/ui_fx.gd`) for pause-input + fade transitions + focus helpers.
- Prefer `UIStyle` (`src/ui/ui_style.gd`) for styling buttons/labels; avoid duplicating StyleBox definitions across scenes.
- Always set an initial focus target (gamepad/keyboard navigation).
