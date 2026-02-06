# Balance

This project is designed to keep gameplay balance **data-driven** and **system-based**.

## Goals

- Avoid the "too many enemies + too little damage" failure mode.
- Make level-up pacing tunable without touching gameplay logic.
- Ensure upgrades are plentiful, consistent, and extendable.

## Where To Change Numbers

- XP curve: `src/systems/balance/progression_config.gd`
- Spawn pacing: `src/systems/balance/spawn_config.gd`
- Enemy scaling: `src/systems/balance/enemy_scaling_config.gd`
- Player base stats: `src/systems/balance/player_config.gd`
- Weapon scaling (per weapon level): `src/systems/balance/weapon_scaling_config.gd`
- Adaptive pressure: `src/systems/balance/encounter_director.gd`
- Fog overlay: `src/systems/balance/fog_config.gd`

## Core Runtime Systems

- `Balance` autoload: `src/autoloads/balance.gd`
- `Stats` autoload: `src/autoloads/stats.gd`
- `Metrics` autoload: `src/autoloads/metrics.gd`

## Upgrade Content

- Upgrades live in `src/systems/upgrades/upgrade_catalog.gd` as `UpgradeData` entries.
- Each upgrade applies via `Stats` using `UpgradeData.stat_name` (no direct mutation of gameplay numbers).

## Workflow

1. Adjust config values.
2. Run `./scripts/validate.sh`.
3. Playtest a short run focusing on time-to-kill, level pacing, and enemy density.
