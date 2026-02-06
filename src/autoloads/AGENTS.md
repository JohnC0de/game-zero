# src/autoloads/

Global singletons configured in `project.godot` `[autoload]`.

## Where To Look

| Autoload | Location | Role |
|----------|----------|------|
| `Game` | `src/autoloads/game.gd` | authoritative run state + XP/level + pause/game-over |
| `Events` | `src/autoloads/events.gd` | typed event bus (signals between systems/UI) |
| `Balance` | `src/autoloads/balance.gd` | reads balance Resources, exposes query funcs |
| `Stats` | `src/autoloads/stats.gd` | run-scoped additive/multiplicative modifiers |
| `Metrics` | `src/autoloads/metrics.gd` | performance counters (e.g. kills/min) |
| `ScreenFX` | `src/autoloads/screen_fx.gd` | hitstop/shake style helpers |
| `SaveData` | `src/autoloads/save_data.gd` | unlocks/progress persistence |
| `Log` | `src/autoloads/logger.gd` | structured logging helpers |

## Conventions

- If you add/remove an autoload, update `project.godot` `[autoload]`.
- Signals must be typed end-to-end (mismatched signal types can fail silently).
- Prefer `Events.*.emit(...)` with typed payloads (e.g. `UpgradeData`) over raw `Dictionary` payloads.

## Anti-Patterns

- Reading `Dictionary` values with `int()/float()` under strict typing; use `as` casts (`memory.md`).
