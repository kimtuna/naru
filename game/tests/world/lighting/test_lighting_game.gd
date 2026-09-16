extends "res://tests/life/harvest/harvest_test_base.gd"
## G-005 2단계 — 게임 씬에서: 밤이 되면 월드가 어두워지고, 램프 자리 광원은 반경 밖을 바꾸지 않는다.

const NIGHT_AT := 700.0


func test_game_darkens_at_night() -> void:
	var game := _enter()
	var cfg := LightingConfig.load_default()
	assert_eq(game.lighting().clock, game.clock())
	assert_almost_eq(game.lighting().darkness().color.r, cfg.day_brightness, 0.001)
	game.clock().advance(NIGHT_AT)
	assert_almost_eq(game.lighting().darkness().color.r, cfg.night_brightness, 0.001, "world darkens at night")
	assert_eq(game.lighting().darkness().get_canvas(), game.player().get_canvas(), "darkness is on the world canvas")
	assert_ne(game.lighting().darkness().get_canvas(), game.hotbar_view().get_canvas(), "HUD is not darkened")
	await _leave_physics_frame()


func test_game_lamp_only_lights_its_radius() -> void:
	var game := _enter()
	game.clock().advance(NIGHT_AT)
	var at := game.player().global_position
	var far := at + Vector2(LightingConfig.load_default().lamp_radius + 1.0, 0)
	var before_far := game.lighting().brightness_at(far)
	var before_at := game.lighting().brightness_at(at)
	game.lighting().add_light(at)
	assert_eq(game.lighting().brightness_at(far), before_far, "outside radius unchanged")
	assert_gt(game.lighting().brightness_at(at), before_at, "lamp spot is lit")
	await _leave_physics_frame()
