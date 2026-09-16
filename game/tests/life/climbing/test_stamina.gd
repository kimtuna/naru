extends GutTest
## G-014 2단계 — 기력: 절벽에서 움직일 때만 줄고, 밖에서 차오르고, 초록 → 주황 → 빨강, 0 뒤의 여유, 수치는 한 곳.

const Zone := Stamina.Zone


func _cfg() -> ClimbingConfig:
	var cfg: ClimbingConfig = ClimbingConfig.load_default().duplicate()
	cfg.max_stamina = 100.0
	cfg.drain_per_second = 10.0
	cfg.regen_per_second = 25.0
	cfg.orange_below = 0.6
	cfg.red_below = 0.3
	cfg.grace = 5.0
	return cfg


func test_drains_only_while_moving_on_cliff() -> void:
	var s := Stamina.new(_cfg())
	assert_eq(s.current, 100.0, "starts full")
	assert_false(s.tick(1.0, true, true))
	assert_almost_eq(s.current, 90.0, 0.001, "moving on cliff drains drain_per_second")
	s.tick(2.0, true, false)
	assert_almost_eq(s.current, 90.0, 0.001, "standing still on cliff does not drain")
	s.tick(1.0, false, true)
	assert_almost_eq(s.current, 100.0, 0.001, "off cliff refills, capped at max")
	s.current = 20.0
	s.tick(0.4, false, false)
	assert_almost_eq(s.current, 30.0, 0.001, "off cliff refills at regen_per_second even when still")


func test_zone_follows_thresholds() -> void:
	var s := Stamina.new(_cfg())
	var cases := [[100.0, Zone.GREEN], [60.0, Zone.GREEN], [59.9, Zone.ORANGE], [30.0, Zone.ORANGE],
		[29.9, Zone.RED], [0.0, Zone.RED]]
	for c in cases:
		s.current = c[0]
		assert_eq(s.zone(), c[1], "stamina %s" % c[0])


func test_zone_changes_in_order_while_climbing() -> void:
	var s := Stamina.new(_cfg())
	var seen: Array = [s.zone()]
	for i in 200:
		s.tick(0.1, true, true)
		if s.zone() != seen.back():
			seen.append(s.zone())
	assert_eq(seen, [Zone.GREEN, Zone.ORANGE, Zone.RED])


func test_grace_after_empty_before_fall() -> void:
	var s := Stamina.new(_cfg())
	s.current = 1.0
	assert_false(s.tick(0.1, true, true), "reaches exactly 0")
	assert_eq(s.current, 0.0)
	assert_false(s.tick(10.0, true, false), "empty but still — no fall")
	assert_false(s.tick(0.4, true, true), "4 of 5 grace used — no fall yet")
	assert_almost_eq(s.overdraw, 4.0, 0.001)
	assert_false(s.tick(0.1, true, true), "exactly at grace — still holds")
	assert_true(s.tick(0.01, true, true), "past grace — falls")


func test_red_zone_alone_never_falls() -> void:
	var s := Stamina.new(_cfg())
	s.current = 25.0
	assert_eq(s.zone(), Zone.RED)
	for i in 24:
		assert_false(s.tick(0.1, true, true), "red with stamina left must not fall (step %d)" % i)


func test_leaving_cliff_clears_grace() -> void:
	var s := Stamina.new(_cfg())
	s.current = 0.0
	s.tick(0.4, true, true)
	s.tick(0.1, false, false)
	assert_eq(s.overdraw, 0.0)
	assert_false(s.tick(0.4, true, true), "grace is whole again")


func test_values_live_in_one_config() -> void:
	var cfg := ClimbingConfig.load_default()
	assert_not_null(cfg, "climbing_config.tres loads")
	for key in ["max_stamina", "drain_per_second", "regen_per_second", "orange_below", "red_below",
			"grace", "climb_speed", "fall_speed", "fall_damage"]:
		assert_gt(float(cfg.get(key)), 0.0, key)
	assert_lt(cfg.red_below, cfg.orange_below, "red boundary below orange")
	assert_lte(cfg.orange_below, 1.0)
	# 코드가 설정 값을 그대로 쓴다.
	assert_eq(Stamina.new().current, cfg.max_stamina)
	assert_eq((autofree(Climber.new()) as Climber).config.fall_damage, cfg.fall_damage)
	var p: Player = autofree(load("res://player/player.tscn").instantiate())
	assert_eq(p.climb_speed, cfg.climb_speed)
