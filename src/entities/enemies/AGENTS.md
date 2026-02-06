# src/entities/enemies/

Enemies (base + variants).

## Where To Look

| File | Role |
|------|------|
| `src/entities/enemies/enemy_base.gd` | health, movement hook, damage flash, death -> `Events.enemy_killed` |
| `src/systems/wave_spawner.gd` | chooses enemy scenes by time + applies scaling |

## Conventions

- Implement per-enemy movement by overriding `_update_behavior(delta)` in subclasses.
- Enemy hitbox `Area2D` must be in group `enemy_hitbox` for player contact damage.
