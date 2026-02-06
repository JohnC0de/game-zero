# src/systems/

Runtime systems (non-entity logic) and submodules.

## Where To Look

| Task | Location | Notes |
|------|----------|-------|
| Arena containers + spawn helpers | `src/systems/game_arena.gd` | sets group `arena`, spawns XP gems on `Events.enemy_killed` |
| Enemy wave spawning | `src/systems/wave_spawner.gd` | reads `Balance`, uses `EncounterDirector` + `Metrics` |
| Upgrade selection + application | `src/systems/upgrade_manager.gd` | group `upgrade_manager`, emits `Events.upgrade_selected` |

## Conventions

- Systems often find peers via groups (e.g. `arena`, `upgrade_manager`) instead of fixed node paths.
- When pausing for level-up/game-over, `Game` pauses the tree; UI must opt-in to `PROCESS_MODE_ALWAYS` if it needs input.

## Anti-Patterns

- Creating a second source of truth for XP/leveling; `Game.add_xp(amount)` is authoritative.
