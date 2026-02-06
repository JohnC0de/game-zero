# src/systems/balance/

Data-driven balance knobs (typed Resources). These are the single source of truth for gameplay numbers.

## Where To Look

| Topic | Location |
|-------|----------|
| XP curve | `src/systems/balance/progression_config.gd` |
| Spawn pacing/count | `src/systems/balance/spawn_config.gd` |
| Enemy scaling | `src/systems/balance/enemy_scaling_config.gd` |
| Adaptive pressure | `src/systems/balance/encounter_director.gd` |
| Player base stats | `src/systems/balance/player_config.gd` |
| Weapon scaling | `src/systems/balance/weapon_scaling_config.gd` |
| Wiring container | `src/systems/balance/balance_config.gd` |

## Conventions

- Gameplay code should call `Balance.*` query functions, not embed numbers.
- Keep knobs reusable and composable; prefer adding a new exported field to a Resource over hardcoding.

## Anti-Patterns

- Hardcoding balance numbers inside gameplay logic (spawners, weapons, entities, UI).
