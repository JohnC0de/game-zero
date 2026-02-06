# src/entities/player/

Player entity (movement, health, i-frames, weapon mounting).

## Where To Look

- `src/entities/player/player.gd` handles:
  - movement gated by `Game.state == PLAYING`
  - damage + invincibility timer
  - weapon mounting + re-emitting `WeaponNode.upgraded` via `Events.weapon_upgraded`
  - XP collection via `Game.add_xp(amount)`
- `src/entities/player/player.tscn` defines the node tree (WeaponMount, PickupArea, Hitbox, Camera2D, timers).

## Conventions

- Base stats come from `Balance.get_player_config()`; run-time modifiers come from `Stats`.
- Do not keep separate XP counters on the Player; `Game` is authoritative.
