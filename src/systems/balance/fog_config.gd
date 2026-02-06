extends Resource
class_name FogConfig

## Simple top-down fog overlay parameters (screen-space).
## This is intentionally not "fog-of-war" persistence (infinite arena) - it's visibility/darkness.

@export var visibility_radius_px: float = 420.0
@export var edge_softness_px: float = 240.0

@export_range(0.0, 1.0, 0.01) var darkness_alpha: float = 0.85

@export_range(0.0, 0.5, 0.01) var noise_strength: float = 0.06
@export var noise_scale: float = 0.02
