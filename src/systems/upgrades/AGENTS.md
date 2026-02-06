# src/systems/upgrades/

Upgrade data and selection utilities.

## Where To Look

| Task | Location | Notes |
|------|----------|-------|
| Stat upgrade catalog | `src/systems/upgrades/upgrade_catalog.gd` | returns `Array[UpgradeData]` |
| Weighted selection | `src/systems/upgrades/weighted_picker.gd` | used by `UpgradeManager` |
| Upgrade resource type | `src/resources/upgrade_data.gd` | typed fields (rarity, weights, etc.) |

## Conventions

- Add new stat upgrades by extending `UpgradeCatalog.get_all()`.
- Upgrades should apply via `Stats` (multipliers/additions), not by mutating individual weapons directly.
- `UpgradeManager` also manufactures weapon upgrades/new-weapon offers; keep weapon names consistent.

## Anti-Patterns

- Emitting upgrade events with untyped payloads; prefer `UpgradeData` through `Events.upgrade_selected`.
