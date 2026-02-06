# src/entities/

Runtime actors: player, enemies, weapons, pickups.

## Structure

```text
entities/
├── player/   # Player scene + script
├── enemies/  # EnemyBase + enemy variants
├── weapons/  # WeaponNode base + weapon variants + projectiles
└── pickups/  # XP gems and other collectibles
```

## Where To Look

| Topic | Location |
|-------|----------|
| Player movement/health/weapons | `src/entities/player/player.gd` |
| Enemy base behavior + death | `src/entities/enemies/enemy_base.gd` |
| Weapon upgrade signaling | `src/entities/weapons/weapon_node.gd` |
| XP pickup | `src/entities/pickups/xp_gem.gd` |

## Conventions

- Enemy contact damage flows via the `enemy_hitbox` group on an enemy `Area2D`.
- Enemy deaths emit `Events.enemy_killed(enemy, pos)`; arena listens and spawns XP gems.
