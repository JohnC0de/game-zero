# Memory: Common Pitfalls & Lessons Learned

This file tracks bugs, mistakes, and patterns we've encountered. **Consult before implementing, update after fixing.**

---

## UI & Input

### Paused Game Blocks UI Input
**Date**: 2026-02-05  
**Symptom**: UI buttons don't respond to clicks  
**Root Cause**: When `get_tree().paused = true`, nodes with default `PROCESS_MODE_INHERIT` stop processing input  
**Fix**: Set `process_mode = Node.PROCESS_MODE_ALWAYS` on UI that must remain interactive during pause  
**Files affected**: `src/ui/level_up_ui.gd`

```gdscript
# In _ready() for any UI that needs to work while paused:
process_mode = Node.PROCESS_MODE_ALWAYS
```

### Game Over UI Buttons Don't Click
**Date**: 2026-02-06  
**Symptom**: Restart/Menu buttons on game over screen don't respond  
**Root Cause**: `Game` pauses the SceneTree in `GAME_OVER`, so `CanvasLayer` with default `PROCESS_MODE_INHERIT` stops processing input  
**Fix**: Set `process_mode = Node.PROCESS_MODE_ALWAYS` in game-over UI `_ready()`  
**Files affected**: `src/ui/game_over.gd`

```gdscript
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
```

### Autoload Name Conflicts With `class_name`
**Date**: 2026-02-06  
**Symptom**: Compile errors like "Class \"Stats\" hides an autoload singleton" and calls like `Stats.get_mul(...)` fail as "non-static".
**Root Cause**: The autoload singleton name (e.g. `Stats`) collides with a global class name registered via `class_name Stats`.
**Fix**: Do not use `class_name` with the same identifier as an autoload; remove `class_name` or rename one side.
**Files affected**: `src/autoloads/stats.gd`

```gdscript
# BAD (autoload is also named Stats)
extends Node
class_name Stats

# GOOD
extends Node
```

---

## GDScript Patterns

### For Loop Iterators Must Be Typed
**Date**: 2026-02-05  
**Symptom**: "for iterator variable has an implicitly inferred static type" error  
**Root Cause**: With `inferred_declaration=2`, for loop variables need explicit types  
**Fix**: Add type annotation to loop variable

```gdscript
# BAD - untyped iterator
for child in container.get_children():
for i in count:

# GOOD - typed iterator
for child: Node in container.get_children():
for i: int in count:
for weapon: Node2D in weapons:
```

### Signal Type Mismatch Causes Silent Failures
**Date**: 2026-02-05  
**Symptom**: Signal handler never fires, no error shown  
**Root Cause**: Signal declared with one type (e.g., `Resource`) but emitted with another (e.g., `Dictionary`). Godot silently ignores the mismatch.  
**Fix**: Ensure signal declaration matches what's actually emitted  
**Files affected**: `src/autoloads/events.gd`, `src/autoloads/game.gd`

```gdscript
# BAD - type mismatch (handler never fires)
signal upgrade_selected(upgrade: Resource)  # declared
Events.upgrade_selected.emit(my_upgrade)    # emitting UpgradeData

# GOOD - types match
signal upgrade_selected(upgrade: UpgradeData)
Events.upgrade_selected.emit(my_upgrade)
```

Prefer passing a typed `Resource` (like `UpgradeData`) over raw `Dictionary` payloads for event bus signals.

**Also applies to weapons** (signals typed `Resource` but emit `Node2D` will silently break handlers):

```gdscript
# BAD
signal weapon_added(weapon: Resource)
Events.weapon_added.emit(weapon_node)

# GOOD
signal weapon_added(weapon: Node2D)
Events.weapon_added.emit(weapon_node)
```

### XP Must Have Single Source Of Truth
**Date**: 2026-02-06  
**Symptom**: XP bar jumps / level-up math desyncs after leveling  
**Root Cause**: `Player` kept its own `xp` counter (total XP) while `Game` treated XP as "toward next level" and subtracts on level-up  
**Fix**: Make `Game` authoritative for XP (`Game.add_xp(amount)`), and have pickups route XP to `Game` (no separate `Player.xp`)  
**Files affected**: `src/autoloads/game.gd`, `src/entities/player/player.gd`

```gdscript
# In Player
func collect_xp(amount: int) -> void:
    Game.add_xp(amount)
```

### Unify Weapon Level/Upgrade Signaling
**Date**: 2026-02-06  
**Symptom**: Some weapons upgrade but no global event fires (HUD/analytics miss upgrades)  
**Root Cause**: Only some weapon scripts had an `upgraded` signal / consistent `level` field  
**Fix**: Use a shared base (`WeaponNode`) that owns `level` and emits `upgraded(new_level)`; re-emit via `Events.weapon_upgraded` from `Player.add_weapon()`  
**Files affected**: `src/entities/weapons/weapon_node.gd`, `src/entities/player/player.gd`

### Lambda Functions Need Return Type
**Date**: 2026-02-05  
**Symptom**: "Function has no static return type" error on lambdas  
**Root Cause**: Anonymous functions need `-> void` or appropriate return type  
**Fix**: Add return type to lambda

```gdscript
# BAD
signal.connect(func(): do_thing())

# GOOD
signal.connect(func() -> void: do_thing())
```

### Dictionary Values Return Variant - Use `as` Cast
**Date**: 2026-02-05  
**Symptom**: Compilation errors like "requires subtype int/bool/float but Variant was provided" or "unsafe cast"  
**Root Cause**: `Dictionary.get()` and `dict[key]` return `Variant`. With strict typing enabled, `int()` and `float()` constructors reject Variant.  
**Fix**: Use `as` cast instead of constructor functions  
**Files affected**: `src/autoloads/save_data.gd`

```gdscript
# BAD - int() doesn't accept Variant
var kills: int = int(stats.get("kills", 0))

# GOOD - use 'as' cast
var kills: int = stats.get("kills", 0) as int

# For JSON parsing (json.data is Variant):
var data: Variant = json.data
if not data is Dictionary:
    return
var d: Dictionary = data as Dictionary
var value: int = d.get("key", 0) as int
```

---

## Godot Gotchas

### Godot Caches Scripts - Clear After External Edits
**Date**: 2026-02-05  
**Symptom**: Editor crashes with script errors even though file is correct  
**Root Cause**: Godot caches compiled scripts in `.godot/` folder. External edits may not be picked up.  
**Fix**: Clear cache and restart editor

```bash
rm -rf .godot/editor .godot/imported
godot --editor .
```

### PackedColorArray Serialization in .tscn/.tres
**Date**: 2026-02-06  
**Symptom**: Scene fails to load with `Parse Error: Expected float in constructor`.
**Root Cause**: `PackedColorArray(...)` in text resources expects raw float components, not `Color(...)` constructors.
**Fix**: Serialize as `PackedColorArray(r,g,b,a, r,g,b,a, ...)`.
**Files affected**: `src/ui/level_up_ui.tscn`

```text
# BAD
colors = PackedColorArray(Color(0.2, 0.9, 1.0, 0.0), Color(1.0, 0.9, 0.2, 0.25))

# GOOD
colors = PackedColorArray(0.2, 0.9, 1.0, 0.0, 1.0, 0.9, 0.2, 0.25)
```

### gdUnit4 Requires Exact directory_rules Key
**Date**: 2026-02-05  
**Symptom**: "GdUnit4: 'inferred_declaration' is set to Warning/Error! Loading GdUnit4 Plugin failed."  
**Root Cause**: gdUnit4's plugin.gd checks for exact key `"res://addons/gdUnit4"` in directory_rules, not prefix match  
**Fix**: Add the exact path gdUnit4 expects to directory_rules in project.godot

```ini
# In project.godot [debug] section:
gdscript/warnings/directory_rules={
"res://addons/": 0,
"res://addons/gdUnit4": 0,
"res://test/": 0
}
```

### Camera Shake Can Leave Permanent Offset
**Date**: 2026-02-06  
**Symptom**: Camera stays slightly shifted after screen shake ends  
**Root Cause**: Shake code only updates `Camera2D.offset` while shaking; when shake amount reaches 0, offset isn't reset  
**Fix**: When shake stops, set `camera.offset = Vector2.ZERO`  
**Files affected**: `src/autoloads/screen_fx.gd`

---

## Performance

*(Add entries as discovered)*

### Pool Short-Lived FX Nodes
**Date**: 2026-02-06  
**Symptom**: Stutters/GC spikes during heavy combat (many hits + deaths)  
**Root Cause**: Per-hit/per-death FX nodes were allocated and freed constantly (`DamageNumber.new()` + `queue_free()`, `DeathParticles.new()` + `queue_free()`)  
**Fix**: Add small static pools in the FX scripts and recycle nodes instead of freeing them  
**Files affected**: `src/effects/damage_number.gd`, `src/effects/death_particles.gd`, `src/entities/enemies/enemy_base.gd`

### Avoid Hard-Coded Base Stats
**Date**: 2026-02-06  
**Symptom**: Base HP/weapon scaling constants drift across scripts/scenes  
**Root Cause**: Base stats and scaling rules were embedded in gameplay logic (`Player`/`WeaponBase`)  
**Fix**: Move base player stats and weapon scaling rules into balance config resources (`PlayerConfig`, `WeaponScalingConfig`) accessed through `Balance`  
**Files affected**: `src/systems/balance/player_config.gd`, `src/systems/balance/weapon_scaling_config.gd`, `src/autoloads/balance.gd`, `src/entities/player/player.gd`, `src/entities/weapons/weapon_base.gd`
