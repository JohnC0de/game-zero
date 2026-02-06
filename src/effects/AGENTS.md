# src/effects/

Visual effects helpers (damage numbers, particles, backgrounds).

## Where To Look

- `src/effects/damage_number.gd` is used by enemies on hit.
- `src/effects/death_particles.gd` is used by enemies on death.
- `src/autoloads/screen_fx.gd` owns global hitstop/shake.

## Conventions

- Prefer pooling/reuse for short-lived FX nodes (see `memory.md` performance notes).
