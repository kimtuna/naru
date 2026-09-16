extends GutTest
## G-011 1단계 — 휘두르면 무엇이 맞나: 바라보는 방향 앞, 손이 닿는 범위 안. 커서 위치와는 상관없다.

const REACH := 32.0
const R := 8.0

var _cfg: SwingConfig


func before_each() -> void:
	_cfg = SwingConfig.load_default()


func _t(pos: Vector2, what: Variant) -> SwingTarget:
	return SwingTarget.create(pos, R, Callable(), what)


func _pick(facing: Vector2, targets: Array) -> Variant:
	var t := SwingAim.pick(Vector2.ZERO, facing.normalized(), REACH, _cfg.half_arc(), targets)
	return t.what if t else null


func test_hits_target_in_front_within_reach() -> void:
	assert_eq(_pick(Vector2.RIGHT, [_t(Vector2(16, 0), "a")]), "a")
	assert_eq(_pick(Vector2.UP, [_t(Vector2(0, -30), "a")]), "a")


func test_target_need_not_be_under_the_facing_line() -> void:
	# 바라보는 방향에서 조금 비껴 있어도 앞이면 맞는다 (커서가 대상 위에 없다).
	var off := Vector2(16, 0).rotated(_cfg.half_arc() * 0.8)
	assert_eq(_pick(Vector2.RIGHT, [_t(off, "a")]), "a")


func test_behind_side_and_out_of_reach_are_not_hit() -> void:
	assert_null(_pick(Vector2.RIGHT, [_t(Vector2(-16, 0), "back")]))
	var side := Vector2(16, 0).rotated(_cfg.half_arc() + 0.2)
	assert_null(_pick(Vector2.RIGHT, [_t(side, "side")]))
	assert_null(_pick(Vector2.RIGHT, [_t(Vector2(REACH + 1.0, 0), "far")]))
	assert_eq(_pick(Vector2.RIGHT, [_t(Vector2(REACH - 1.0, 0), "near")]), "near")


func test_nearest_on_the_line_wins_and_blocks_the_one_behind() -> void:
	var targets := [_t(Vector2(30, 0), "back"), _t(Vector2(14, 2), "front")]
	assert_eq(_pick(Vector2.RIGHT, targets), "front")


func test_on_the_line_beats_nearer_off_line() -> void:
	var side := Vector2(12, 0).rotated(0.9)
	var targets := [_t(side, "side"), _t(Vector2(28, 0), "ahead")]
	assert_eq(_pick(Vector2.RIGHT, targets), "ahead")


func test_without_line_hit_the_smallest_angle_wins() -> void:
	var targets := [_t(Vector2(20, 0).rotated(0.9), "wide"), _t(Vector2(24, 0).rotated(-0.6), "narrow")]
	assert_eq(_pick(Vector2.RIGHT, targets), "narrow")


func test_picking_does_not_depend_on_order() -> void:
	var a := _t(Vector2(14, 0), "a")
	var b := _t(Vector2(28, 0), "b")
	assert_eq(_pick(Vector2.RIGHT, [a, b]), "a")
	assert_eq(_pick(Vector2.RIGHT, [b, a]), "a")


func test_nothing_to_hit() -> void:
	assert_null(_pick(Vector2.RIGHT, []))


func test_swing_values_live_in_one_config() -> void:
	assert_gt(_cfg.swing_interval, 0.0)
	assert_gt(_cfg.reach_tiles, 0.0)
	assert_gt(_cfg.arc_degrees, 0.0)
	assert_lt(_cfg.arc_degrees, 360.0)
	var harvest := HarvestConfig.load_default()
	assert_false("swing_interval" in harvest, "swing interval must not be duplicated in HarvestConfig")
	assert_false("reach_tiles" in harvest, "reach must not be duplicated in HarvestConfig")
	var stations := Stations.new()
	add_child_autofree(stations)
	assert_true(stations.config is SwingConfig, "stations reach must come from the same swing config")
