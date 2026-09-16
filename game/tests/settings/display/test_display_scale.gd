extends GutTest
## G-010 1단계 — 기준 화면 640×360 과 배율. 창 크기가 달라도 보이는 월드 범위가 같고,
## 16:9 가 아니면 검은 띠, 글자 · UI 는 같은 비율로 커지며, 보이는 범위를 바꾸는 설정이 없다.

const GAME := "res://world/game.tscn"
const MAIN_MENU := "res://ui/menu/main_menu.tscn"
const SETTINGS := "res://ui/menu/settings.tscn"
const SEED := 20260917
## 수용 기준의 창 크기들.
const WINDOWS := [
	Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440),
	Vector2i(2560, 1080), Vector2i(1280, 800),
]
## 기준 화면 640×360 을 16px 타일로 본 칸 수.
const VIEW_TILES := Vector2(40.0, 22.5)
## 보이는 범위를 바꾸는 설정 · 조작을 가리키는 낱말 (이름 · 번역 키에 있으면 안 된다).
const ZOOM_WORDS := ["zoom", "fov", "view_range", "viewrange", "view_distance", "camera"]

var _root := ""
var _saved_size := Vector2i.ZERO


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_display_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	_saved_size = get_tree().root.size


func after_each() -> void:
	get_tree().root.size = _saved_size
	Screens.simulate = false
	Session.store = SaveStore.new()
	Session.clear()
	for dir in [SaveConfig.CHARACTER_DIR, SaveConfig.WORLD_DIR]:
		var p := _root.path_join(dir)
		if DirAccess.dir_exists_absolute(p):
			for f in DirAccess.get_files_at(p):
				DirAccess.remove_absolute(p.path_join(f))
			DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(_root)


func _enter() -> GameScene:
	var c := CharacterData.new()
	c.name = "tester"
	assert_eq(Session.store.save_character(0, c), OK)
	var id := Session.store.create_world(WorldData.create("island", SEED))
	Session.select_character(0)
	Session.select_world(id)
	return add_child_autofree((load(GAME) as PackedScene).instantiate())


func _resize(size: Vector2i) -> void:
	get_tree().root.size = size
	await wait_process_frames(2)


## 창(실제 픽셀)에서 게임 화면이 차지하는 사각형.
func _content_rect_in_window() -> Rect2:
	var root := get_tree().root
	return root.get_final_transform() * root.get_visible_rect()


## 지금 화면에 보이는 월드 사각형 (월드 픽셀).
func _visible_world_rect() -> Rect2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()


func test_project_uses_base_screen_and_fixed_stretch() -> void:
	assert_eq(DisplayConfig.BASE_SIZE, Vector2i(640, 360))
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), DisplayConfig.BASE_SIZE.x)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), DisplayConfig.BASE_SIZE.y)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_width_override"), DisplayConfig.WINDOW_SIZE.x)
	assert_eq(ProjectSettings.get_setting("display/window/size/window_height_override"), DisplayConfig.WINDOW_SIZE.y)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), DisplayConfig.STRETCH_MODE)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), DisplayConfig.STRETCH_ASPECT)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), DisplayConfig.STRETCH_SCALE_MODE)
	# 실제 창에 적용됐는지.
	var root := get_tree().root
	assert_eq(root.content_scale_size, DisplayConfig.BASE_SIZE)
	assert_eq(root.content_scale_mode, Window.CONTENT_SCALE_MODE_VIEWPORT)
	assert_eq(root.content_scale_aspect, Window.CONTENT_SCALE_ASPECT_KEEP)
	assert_eq(root.content_scale_stretch, Window.CONTENT_SCALE_STRETCH_INTEGER)


func test_visible_world_range_is_same_for_every_window_size() -> void:
	var game := _enter()
	await wait_process_frames(2)
	var tile := float(game.island_view().tile_px())
	assert_eq(tile, 16.0)
	var cam := game.player().camera()
	assert_eq(get_viewport().get_camera_2d(), cam)
	for size in WINDOWS:
		await _resize(size)
		assert_eq(get_tree().root.size, size, "window size not applied")
		var world := _visible_world_rect()
		assert_eq(world.size / tile, VIEW_TILES, "window %s sees %s tiles" % [size, world.size / tile])
		assert_eq(cam.zoom, DisplayConfig.CAMERA_ZOOM, "camera zoom changed at %s" % size)
		# 섬 조각도 같은 범위 기준으로 만든다.
		assert_eq(game.island_view().visible_half_extent(), world.size / 2.0)


func test_16_9_windows_fill_with_integer_scale_and_no_bars() -> void:
	for size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		await _resize(size)
		var rect := _content_rect_in_window()
		assert_eq(rect, Rect2(Vector2.ZERO, Vector2(size)), "window %s content %s" % [size, rect])
		var scale := get_tree().root.get_final_transform().get_scale()
		assert_eq(scale, Vector2.ONE * (size.x / 640), "window %s scale %s" % [size, scale])


func test_non_16_9_windows_get_black_bars_not_more_view() -> void:
	# 2560×1080 → 3배 (1920×1080) + 좌우 320 띠 · 1280×800 → 2배 (1280×720) + 위아래 40 띠.
	var cases := {
		Vector2i(2560, 1080): Rect2(320, 0, 1920, 1080),
		Vector2i(1280, 800): Rect2(0, 40, 1280, 720),
	}
	for size in cases:
		await _resize(size)
		var rect := _content_rect_in_window()
		assert_eq(rect, cases[size], "window %s content %s" % [size, rect])
		# 비율은 16:9 그대로 — 남는 곳은 게임이 그리지 않는 띠다.
		assert_almost_eq(rect.size.x / rect.size.y, 16.0 / 9.0, 0.0001)
		assert_true(Rect2(Vector2.ZERO, Vector2(size)).encloses(rect))
		assert_gt(float(size.x * size.y), rect.get_area(), "no bars at %s" % size)
		# 게임 화면 크기는 기준 화면 그대로 — 옆이나 위아래가 더 보이지 않는다.
		assert_eq(get_viewport().get_visible_rect().size, Vector2(640, 360))
	# 띠는 검은색이다 — 기본 배경색이 아니라 엔진이 띠를 비워 둔다 (viewport 모드는 늘 검다).
	assert_eq(get_tree().root.content_scale_mode, Window.CONTENT_SCALE_MODE_VIEWPORT)


func test_text_and_ui_scale_with_window() -> void:
	var menu: Control = add_child_autofree((load(MAIN_MENU) as PackedScene).instantiate())
	var title := menu.get_node("Title") as Label
	var start := menu.get_node("%Start") as Button
	var base := {}
	for size in WINDOWS:
		await _resize(size)
		# 기준 화면 안에서의 배치는 창 크기와 상관없이 같다.
		assert_eq(menu.size, Vector2(640, 360), "menu not laid out on base screen at %s" % size)
		var final := get_tree().root.get_final_transform()
		var k := final.get_scale().x
		var content := _content_rect_in_window()
		for c: Control in [title, start]:
			var on_window: Rect2 = final * c.get_global_rect()
			var font_px: float = c.get_theme_font_size("font_size") * k
			if not base.has(c):
				base[c] = {"rect": c.get_global_rect(), "font": c.get_theme_font_size("font_size")}
			assert_eq(c.get_global_rect(), base[c]["rect"], "%s moved in base screen at %s" % [c.name, size])
			# 창에서 보면 화면과 같은 비율로 커진다 — 화면 대비 크기 · 위치가 같다.
			assert_almost_eq(on_window.size.x / content.size.x, base[c]["rect"].size.x / 640.0, 0.0001)
			assert_almost_eq(on_window.size.y / content.size.y, base[c]["rect"].size.y / 360.0, 0.0001)
			assert_almost_eq((on_window.position.x - content.position.x) / content.size.x,
				base[c]["rect"].position.x / 640.0, 0.0001)
			assert_almost_eq(font_px / content.size.y, float(base[c]["font"]) / 360.0, 0.0001,
				"%s text shrinks relative to window at %s" % [c.name, size])
	# 1280×720 → 2560×1440 이면 글자도 정확히 두 배.
	await _resize(Vector2i(1280, 720))
	var small := (get_tree().root.get_final_transform() * title.get_global_rect()).size
	await _resize(Vector2i(2560, 1440))
	var big := (get_tree().root.get_final_transform() * title.get_global_rect()).size
	assert_eq(big, small * 2.0)


func test_no_input_action_changes_view_range() -> void:
	for action in InputMap.get_actions():
		var a := String(action).to_lower()
		if a.begins_with("ui_"):
			continue
		for w in ZOOM_WORDS:
			assert_false(a.contains(w), "input action %s looks like a view-range control" % action)


func test_wheel_and_zoom_keys_do_not_change_camera() -> void:
	var game := _enter()
	await wait_process_frames(2)
	var cam := game.player().camera()
	var before := _visible_world_rect().size
	var events: Array[InputEvent] = []
	for b in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		for ctrl in [false, true]:
			var ev := InputEventMouseButton.new()
			ev.button_index = b
			ev.pressed = true
			ev.ctrl_pressed = ctrl
			ev.position = Vector2(320, 180)
			events.append(ev)
	for k in [KEY_EQUAL, KEY_MINUS, KEY_KP_ADD, KEY_KP_SUBTRACT, KEY_PAGEUP, KEY_PAGEDOWN]:
		var ev := InputEventKey.new()
		ev.keycode = k
		ev.physical_keycode = k
		ev.pressed = true
		events.append(ev)
	for ev in events:
		Input.parse_input_event(ev)
		Input.flush_buffered_events()
		await wait_process_frames(1)
		var up := ev.duplicate() as InputEvent
		up.set("pressed", false)
		Input.parse_input_event(up)
		Input.flush_buffered_events()
		await wait_process_frames(1)
		assert_eq(cam.zoom, DisplayConfig.CAMERA_ZOOM, "zoom changed by %s" % ev.as_text())
	assert_eq(_visible_world_rect().size, before)


func test_settings_screen_has_no_view_range_option() -> void:
	var screen: Control = add_child_autofree((load(SETTINGS) as PackedScene).instantiate())
	await wait_process_frames(1)
	var nodes: Array[Node] = [screen]
	nodes.append_array(screen.find_children("*", "", true, false))
	for n in nodes:
		var texts := [String(n.name).to_lower()]
		if n is Label or n is Button:
			texts.append(String(n.text).to_lower())
		for t in texts:
			for w in ZOOM_WORDS:
				assert_false(t.contains(w), "settings node %s looks like a view-range option" % n.name)
	# 번역 파일에도 보이는 범위 설정용 글자가 없다.
	for path in ["res://i18n/ko.po", "res://i18n/en.po"]:
		var body := FileAccess.get_file_as_string(path).to_lower()
		assert_ne(body, "", "cannot read " + path)
		for w in ["zoom", "fov", "줌", "시야", "확대"]:
			assert_false(body.contains(w), "%s has a view-range string (%s)" % [path, w])
