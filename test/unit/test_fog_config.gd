extends GdUnitTestSuite


func test_balance_exposes_fog_config() -> void:
	var cfg: FogConfig = Balance.get_fog_config()
	assert_object(cfg).is_not_null()
	assert_float(cfg.visibility_radius_px).is_greater(0.0)
	assert_float(cfg.edge_softness_px).is_greater_equal(0.0)
	assert_float(cfg.darkness_alpha).is_between(0.0, 1.0)
	assert_float(cfg.noise_strength).is_between(0.0, 0.5)
	assert_float(cfg.noise_scale).is_greater(0.0)
