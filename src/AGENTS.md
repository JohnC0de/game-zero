# src/

Gameplay code for Neon Survivor.

## Structure

```text
src/
├── autoloads/   # global singletons (Game/Events/Stats/Balance/...)
├── systems/     # spawners + upgrade selection + balance configs
├── entities/    # player, enemies, weapons, pickups
├── ui/          # menu + HUD + level-up + game-over screens
├── effects/     # particles + damage numbers + screen dressing
└── resources/   # typed Resources (e.g. UpgradeData)
```

## Where To Look

| Task | Location | Notes |
|------|----------|-------|
| Start flow | `src/ui/main_menu.gd` | loads `res://world.tscn` |
| Core run loop/state | `src/autoloads/game.gd` | owns `Game.state`, XP/leveling |
| Spawn enemies | `src/systems/wave_spawner.gd` | uses `Balance` + `EncounterDirector` |
| Arena containers/spawning helpers | `src/systems/game_arena.gd` | group `arena` |
| Generate/apply upgrades | `src/systems/upgrade_manager.gd` | uses `UpgradeCatalog` + `Stats` |
| Add balance knobs | `src/systems/balance/` | Resources consumed by `Balance` |

## Conventions

- Treat `Game.state` as the top-level gate; most `_process/_physics_process` early-return unless `PLAYING`.
- Prefer Events bus signals (`src/autoloads/events.gd`) over direct node-to-node calls for cross-system UI updates.
- Balance numbers live in `src/systems/balance/` Resources; gameplay scripts should query `Balance`.

## Anti-Patterns

- Editing generated artifacts under `build/`, `dist/`, `.godot/`, `reports/`.
- Introducing untyped vars/params/returns (warnings are treated as errors via `project.godot`).
