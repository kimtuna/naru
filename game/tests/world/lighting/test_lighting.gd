extends GutTest
## G-005 2단계 — 밤이면 화면이 어두워지고, 광원은 제 반경만 밝힌다.

const DAY := 1200.0
const NIGHT_AT := 700.0

var _clock: WorldClock
var _lighting: Lighting


func before_each() -> void:
	_clock = WorldClock.new()
	_clock.speed = 0.0
	add_child_autofree(_clock)
	_lighting = Lighting.new()
	add_child_autofree(_lighting)
	_lighting.setup(_clock)


func _cfg() -> LightingConfig:
	return LightingConfig.load_default()


func _gray(c: Color) -> float:
	return (c.r + c.g + c.b) / 3.0


func test_brightness_values_live_in_config_file() -> void:
	var cfg := _cfg()
	assert_not_null(cfg)
	assert_lt(cfg.night_brightness, cfg.day_brightness, "night is darker than day")
	assert_gt(cfg.night_brightness, 0.0, "night is not pitch black")
	assert_gt(cfg.lamp_radius, 0.0)


func test_day_is_not_darkened() -> void:
	assert_false(_clock.is_night())
	assert_almost_eq(_lighting.ambient(), _cfg().day_brightness, 0.001)
	assert_almost_eq(_gray(_lighting.darkness().color), _cfg().day_brightness, 0.001)


func test_screen_darkens_when_night_comes() -> void:
	var day_color := _lighting.darkness().color
	_clock.advance(NIGHT_AT)
	assert_true(_clock.is_night())
	var night_color := _lighting.darkness().color
	assert_almost_eq(_gray(night_color), _cfg().night_brightness, 0.001, "night uses config brightness")
	assert_lt(_gray(night_color), _gray(day_color), "screen gets darker")
	assert_almost_eq(_lighting.brightness_at(Vector2(5000, 5000)), _cfg().night_brightness, 0.001)


func test_screen_brightens_again_in_the_morning() -> void:
	_clock.advance(NIGHT_AT)
	_clock.advance(DAY - NIGHT_AT + 10.0)
	assert_false(_clock.is_night())
	assert_almost_eq(_gray(_lighting.darkness().color), _cfg().day_brightness, 0.001)


func test_night_brightness_comes_from_config() -> void:
	var cfg := LightingConfig.new()
	cfg.night_brightness = 0.12
	_lighting.config = cfg
	_clock.advance(NIGHT_AT)
	assert_almost_eq(_gray(_lighting.darkness().color), 0.12, 0.001)


func test_darkness_is_a_canvas_modulate_in_the_world() -> void:
	assert_true(_lighting.darkness() is CanvasModulate)
	assert_true(_lighting.darkness().is_inside_tree())


func test_light_can_be_placed() -> void:
	var lamp := _lighting.add_light(Vector2(100, 100))
	assert_not_null(lamp)
	assert_eq(_lighting.lights().size(), 1)
	assert_almost_eq(lamp.radius, _cfg().lamp_radius, 0.001, "default radius from config")
	assert_eq(lamp.global_position, Vector2(100, 100))
	assert_true(lamp.light() is PointLight2D)


func test_outside_radius_is_same_as_without_light() -> void:
	_clock.advance(NIGHT_AT)
	var samples := [Vector2(100, 100) + Vector2(96, 0), Vector2(100, 100) + Vector2(0, -97), Vector2(300, 300), Vector2(-500, 20)]
	var without := samples.map(func(p: Vector2) -> float: return _lighting.brightness_at(p))
	_lighting.add_light(Vector2(100, 100), 96.0)
	for i in samples.size():
		assert_eq(_lighting.brightness_at(samples[i]), without[i], "outside radius at %s" % samples[i])


func test_inside_radius_is_brighter_at_night() -> void:
	_clock.advance(NIGHT_AT)
	var dark := _lighting.brightness_at(Vector2(100, 100))
	_lighting.add_light(Vector2(100, 100), 96.0)
	assert_gt(_lighting.brightness_at(Vector2(100, 100)), dark, "center is lit")
	assert_gt(_lighting.brightness_at(Vector2(150, 100)), dark, "inside radius is lit")
	assert_almost_eq(_lighting.brightness_at(Vector2(100, 100)), 1.0, 0.001, "center returns to full brightness")
	assert_lt(_lighting.brightness_at(Vector2(150, 100)), 1.0, "fades toward the edge")


func test_light_does_not_brighten_the_day() -> void:
	var lamp := _lighting.add_light(Vector2.ZERO, 96.0)
	assert_almost_eq(lamp.strength(), 0.0, 0.001)
	assert_almost_eq(_lighting.brightness_at(Vector2.ZERO), _cfg().day_brightness, 0.001)
	_clock.advance(NIGHT_AT)
	assert_gt(lamp.strength(), 0.0, "light turns up at night")


func test_light_texture_covers_only_the_radius() -> void:
	var lamp := _lighting.add_light(Vector2.ZERO, 40.0)
	var tex := lamp.light().texture
	assert_not_null(tex)
	var img := lamp.image()
	assert_not_null(img)
	assert_eq(tex.get_size(), Vector2(img.get_size()), "texture is the tested image")
	assert_almost_eq(img.get_width() * lamp.light().texture_scale / 2.0, 40.0, 0.5, "drawn size matches radius")
	assert_eq(lamp.light().blend_mode, Light2D.BLEND_MODE_ADD, "light adds on top of darkness")
	var w := img.get_width()
	var h := img.get_height()
	assert_gt(_gray(img.get_pixel(w / 2, h / 2)), 0.9, "center is bright")
	for p in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		assert_almost_eq(_gray(img.get_pixel(p.x, p.y)), 0.0, 0.001, "corner %s (outside radius) adds nothing" % p)
	# 가장자리 가운데 = 반경 바로 위 — 거의 0.
	assert_lt(_gray(img.get_pixel(0, h / 2)), 0.05, "edge of radius adds (almost) nothing")


func test_drawn_light_matches_brightness_model() -> void:
	_clock.advance(NIGHT_AT)
	var lamp := _lighting.add_light(Vector2.ZERO, 40.0)
	var img := lamp.image()
	var half := img.get_width() / 2.0
	for x in [20, 30, 45, 55, 70]:
		var pixel := Vector2(x, int(half)) + Vector2(0.5, 0.5)
		var world := pixel - Vector2(half, half)
		var drawn := img.get_pixel(x, int(half)).r * lamp.strength()
		assert_almost_eq(drawn, lamp.contribution_at(world), 0.01, "pixel %d matches model" % x)
