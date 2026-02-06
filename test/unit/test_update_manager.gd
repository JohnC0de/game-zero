extends GdUnitTestSuite


func test_compare_versions_prefers_higher() -> void:
	assert_int(UpdateManager._compare_versions("v1.2.3", "1.2.2")).is_equal(1)
	assert_int(UpdateManager._compare_versions("1.2.3", "v1.2.3")).is_equal(0)
	assert_int(UpdateManager._compare_versions("v0.9.0", "0.10.0")).is_equal(-1)


func test_compare_versions_ignores_suffix() -> void:
	assert_int(UpdateManager._compare_versions("v1.2.3-rc.1", "1.2.3")).is_equal(0)
	assert_int(UpdateManager._compare_versions("1.2.4-alpha", "1.2.3")).is_equal(1)


func test_compare_versions_handles_missing_parts() -> void:
	assert_int(UpdateManager._compare_versions("v1", "1.0.0")).is_equal(0)
	assert_int(UpdateManager._compare_versions("1.2", "1.2.0")).is_equal(0)
	assert_int(UpdateManager._compare_versions("1.2.1", "1.2")).is_equal(1)
