# src/entities/weapons/

Weapons and projectiles.

## Where To Look

| File | Role |
|------|------|
| `src/entities/weapons/weapon_node.gd` | shared level + `upgraded(new_level)` signal |
| `src/entities/weapons/weapon_base.gd` | common weapon behavior/helpers |
| `src/entities/weapons/projectile_base.gd` | common projectile behavior |
| `src/systems/upgrade_manager.gd` | weapon offer + upgrade selection wiring |

## Conventions

- Weapon scripts should expose `weapon_name` (string) and optionally `level` (int via `WeaponNode`).
- Level-up UI/upgrade system expects weapons to implement `upgrade()`.
- Stat scaling should come from `Stats` + `Balance.get_weapon_scaling_config()` rather than per-weapon constants.

## Anti-Patterns

- Adding a new weapon without also wiring it into `UpgradeManager.weapon_scenes` and unlock rules (`SaveData`).
