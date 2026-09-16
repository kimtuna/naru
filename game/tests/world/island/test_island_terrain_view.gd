extends GutTest
## G-013 1단계 — 게임 화면에서 지형마다 다른 색 네모로 보인다 (디자인은 나중).

const Terrain := IslandConfig.Terrain
const GAME := "res://world/game.tscn"
const SEED := 20260916


func test_each_terrain_has_its_own_color() -> void:
	var colors := IslandChunk.TERRAIN_COLORS
	assert_eq(colors.size(), Terrain.size())
	var top := IslandConfig.load_default().max_height
	for a in Terrain.values():
		assert_true(colors.has(a), "지형 %d 색" % a)
		for b in Terrain.values():
			if a >= b:
				continue
			# 높이로 밝아져도 다른 지형과 헷갈리지 않는다.
			for ha in top + 1:
				for hb in top + 1:
					var ca: Color = colors[a].lightened(IslandChunk.HEIGHT_LIGHTEN * ha)
					var cb: Color = colors[b].lightened(IslandChunk.HEIGHT_LIGHTEN * hb)
					var diff := Vector3(ca.r - cb.r, ca.g - cb.g, ca.b - cb.b).length()
					assert_gt(diff, 0.05, "지형 %d(높이 %d) 와 %d(높이 %d) 색이 비슷하다" % [a, ha, b, hb])


func test_game_chunks_draw_terrain_colors() -> void:
	var root := OS.get_temp_dir().path_join("naru_test_terrain_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(root)
	Session.clear()
	var ch := CharacterData.new()
	ch.name = "tester"
	assert_eq(Session.store.save_character(0, ch), OK)
	Session.select_character(0)
	Session.select_world(Session.store.create_world(WorldData.create("island", SEED)))
	var game: GameScene = add_child_autofree((load(GAME) as PackedScene).instantiate())
	var view := game.island_view()
	var map := game.island
	var seen := {}
	for kind in Terrain.values():
		var cell := _find_terrain(map, kind)
		assert_ne(cell, Vector2i(-1, -1), "지형 %d 칸" % kind)
		if cell == Vector2i(-1, -1):
			continue
		game.player().global_position = view.cell_center(cell)
		view.update_around(game.player().global_position)
		var chunk := view.chunk_node(map.chunk_of(cell))
		assert_not_null(chunk)
		assert_true(chunk.is_visible_in_tree())
		var color := chunk.color_at(cell)
		var base: Color = IslandChunk.TERRAIN_COLORS[kind]
		assert_eq(color, base.lightened(IslandChunk.HEIGHT_LIGHTEN * map.height_at(cell)))
		seen[color] = kind
	assert_eq(seen.size(), Terrain.size(), "지형마다 그린 색이 다르다")
	Session.store = SaveStore.new()
	Session.clear()
	_remove_dir(root)


## 스폰에서 가까운 줄부터 — 그 지형의 칸 하나.
func _find_terrain(map: IslandMap, kind: int) -> Vector2i:
	var s := map.spawn()
	for r in map.size:
		for d in range(-r, r + 1):
			for c in [s + Vector2i(d, -r), s + Vector2i(d, r), s + Vector2i(-r, d), s + Vector2i(r, d)]:
				if map.has_cell(c) and map.terrain_at(c) == kind:
					return c
	return Vector2i(-1, -1)


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
