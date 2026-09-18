extends "res://tests/settings/display/fit_test_base.gd"
## G-015 1단계 — 월드 카메라 2배. 보이는 월드는 20×11.25칸, UI 는 640×360 기준 그대로,
## 「화면에 보이는 범위」를 쓰는 코드(섬 덩어리 만들기)는 새 범위를 따른다.

const TILE := 16.0
const VIEW_TILES := Vector2(20.0, 11.25)


func _visible_world_rect() -> Rect2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()


func _hud(game: GameScene) -> CanvasLayer:
	return game.get_node("Hud") as CanvasLayer


func _hud_rects(game: GameScene) -> Dictionary:
	var out := {}
	for n in _hud(game).find_children("*", "Control", true, false):
		var c := n as Control
		if c.is_visible_in_tree():
			out[_hud(game).get_path_to(c)] = c.get_global_rect()
	return out


func test_zoom_is_two_in_display_config_only() -> void:
	assert_eq(DisplayConfig.CAMERA_ZOOM, Vector2(2.0, 2.0))
	assert_eq(Vector2(DisplayConfig.BASE_SIZE) / DisplayConfig.CAMERA_ZOOM / TILE, VIEW_TILES)
	# 카메라 확대를 정하는 곳은 DisplayConfig 하나 — 게임 코드 · 씬 어디에도 zoom 값을 따로 쓰지 않는다.
	var found: Array[String] = []
	_scan("res://", found)
	assert_eq(found, [] as Array[String], "zoom set outside DisplayConfig")


func _scan(dir: String, found: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		if sub.begins_with(".") or sub in ["addons", "tests"]:
			continue
		_scan(dir.path_join(sub), found)
	for f in DirAccess.get_files_at(dir):
		if not (f.ends_with(".gd") or f.ends_with(".tscn")):
			continue
		var path := dir.path_join(f)
		if path == "res://settings/display/display_config.gd":
			continue
		for line in FileAccess.get_file_as_string(path).split("\n"):
			var l := line.strip_edges()
			if l.begins_with("zoom =") or l.contains(".zoom =") or l.contains("zoom = Vector2"):
				found.append("%s: %s" % [path, l])


func test_game_camera_shows_twenty_by_eleven_tiles() -> void:
	var game := _enter()
	await wait_process_frames(2)
	var cam := game.player().camera()
	assert_eq(get_viewport().get_camera_2d(), cam)
	assert_eq(cam.zoom, DisplayConfig.CAMERA_ZOOM)
	assert_eq(_visible_world_rect().size / TILE, VIEW_TILES)
	# 화면 가운데는 여전히 플레이어다.
	assert_almost_eq(_visible_world_rect().get_center(), cam.get_screen_center_position(), Vector2.ONE * 0.01)


func test_hud_and_windows_keep_base_screen_layout() -> void:
	var game := _enter()
	await wait_process_frames(2)
	var hud := _hud(game)
	assert_false(hud.follow_viewport_enabled, "HUD must not follow the world camera")
	assert_eq(hud.get_final_transform(), Transform2D.IDENTITY)
	game.inventory_view().set_open(true)
	await wait_process_frames(2)
	var zoomed := _hud_rects(game)
	assert_gte(zoomed.size(), 3, "nothing visible in HUD")
	# 월드 카메라를 1배로 돌려도 UI 는 한 칸도 안 움직인다 — 카메라 배율과 상관없다.
	game.player().camera().zoom = Vector2.ONE
	await wait_process_frames(2)
	assert_eq(_visible_world_rect().size / TILE, Vector2(40.0, 22.5))
	var plain := _hud_rects(game)
	assert_eq(plain, zoomed, "HUD layout depends on the world camera")
	for path in zoomed:
		assert_true(SCREEN.grow(0.01).encloses(zoomed[path]), "%s outside 640x360" % path)


func test_island_chunks_follow_new_view_range() -> void:
	var game := _enter()
	await wait_physics_frames(2)
	var view := game.island_view()
	var world := _visible_world_rect()
	assert_eq(view.visible_half_extent(), world.size / 2.0)
	assert_eq(view.visible_half_extent(), Vector2(160.0, 90.0))
	# 보이는 네 귀퉁이까지 덩어리가 있고, (보이는 곳 + 여유) 에서 한 덩어리 넘게 먼 덩어리는 없다.
	var center := game.player().global_position
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var cell := view.world_to_cell(center + view.visible_half_extent() * corner)
		assert_not_null(view.chunk_node(game.island.chunk_of(cell)), "corner %s not covered" % corner)
	var span := float(game.island.chunk_size * view.tile_px())
	var half := view.visible_half_extent() + Vector2.ONE * view.config.view_margin_px
	var reach := Rect2(center - half, half * 2.0).grow(span)
	for child in view.get_children():
		if child is IslandChunk:
			var r := Rect2(child.position, Vector2.ONE * span)
			assert_true(reach.intersects(r), "chunk %s built outside the view range" % child.chunk)
