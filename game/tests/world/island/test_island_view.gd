extends GutTest
## G-004 2단계 — 게임 씬에 섬이 보이고 나무 · 돌 · 광물에 막힌다. 256×256 이어도 빨리 들어간다.

const GAME := "res://world/game.tscn"
const SEED := 20260916
const DIRS := {
	InputActions.MOVE_RIGHT: Vector2i.RIGHT,
	InputActions.MOVE_LEFT: Vector2i.LEFT,
	InputActions.MOVE_DOWN: Vector2i.DOWN,
	InputActions.MOVE_UP: Vector2i.UP,
}
## 들어가기 시간 한도 (밀리초) — 넘으면 「길다」로 본다.
const LOAD_LIMIT_MS := 500.0

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_island_view_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()


func after_each() -> void:
	for a in DIRS:
		Input.action_release(a)
	Session.store = SaveStore.new()
	Session.clear()
	for dir in [SaveConfig.CHARACTER_DIR, SaveConfig.WORLD_DIR]:
		var p := _root.path_join(dir)
		if DirAccess.dir_exists_absolute(p):
			for f in DirAccess.get_files_at(p):
				DirAccess.remove_absolute(p.path_join(f))
			DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(_root)


func _select_world(seed_value: int) -> void:
	var c := CharacterData.new()
	c.name = "tester"
	assert_eq(Session.store.save_character(0, c), OK)
	var id := Session.store.create_world(WorldData.create("island", seed_value))
	Session.select_character(0)
	Session.select_world(id)


func _enter(seed_value := SEED) -> GameScene:
	_select_world(seed_value)
	return add_child_autofree((load(GAME) as PackedScene).instantiate())


func _half_body(p: Player) -> Vector2:
	return (p.get_node("Shape").shape as RectangleShape2D).size / 2.0


## 스폰에서 가까운 순으로 — 종류가 deposit 인 칸 c 와, 그 앞 두 칸(c - d, c - 2d)이 비어 있는 곳.
func _find_target(map: IslandMap, deposit: int, d: Vector2i) -> Vector2i:
	var s := map.spawn()
	for r in range(4, 60):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := s + Vector2i(dx, dy)
				if not map.has_cell(c) or not map.has_cell(c - d * 2):
					continue
				if map.deposit_at(c) == deposit and not map.is_blocked(c - d) and not map.is_blocked(c - d * 2):
					return c
	return Vector2i(-1, -1)


## 플레이어를 칸 한가운데로 옮기고 그 둘레 섬을 만든다.
func _teleport(game: GameScene, cell: Vector2i) -> void:
	game.player().global_position = game.island_view().cell_center(cell)
	game.player().velocity = Vector2.ZERO
	game.island_view().update_around(game.player().global_position)
	await wait_physics_frames(2)


## 방향키를 누른 채 걷고, 얼마나 갔는지(방향 성분)를 돌려준다.
func _walk(game: GameScene, action: StringName, frames: int) -> float:
	var start := game.player().global_position
	Input.action_press(action)
	await wait_physics_frames(frames)
	Input.action_release(action)
	await wait_physics_frames(1)
	return (game.player().global_position - start).dot(Vector2(DIRS[action]))


# --- 섬이 보인다 ---

func test_island_is_shown_around_player_at_spawn() -> void:
	var game := _enter()
	var view := game.island_view()
	assert_not_null(view.map, "view has no island")
	assert_eq(view.map, game.island)
	assert_true(view.is_visible_in_tree())
	var spawn := game.island.spawn()
	assert_eq(view.world_to_cell(game.player().global_position), spawn, "player starts on spawn cell")
	var chunk := view.chunk_node(game.island.chunk_of(spawn))
	assert_not_null(chunk, "chunk under player not built")
	assert_true(chunk.is_visible_in_tree())
	assert_eq(chunk.position, Vector2(game.island.chunk_rect(chunk.chunk).position * view.tile_px()))
	# 화면 네 귀퉁이까지 덩어리가 덮는다.
	var half := view.visible_half_extent()
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var cell := view.world_to_cell(game.player().global_position + half * corner)
		assert_not_null(view.chunk_node(game.island.chunk_of(cell)), "screen corner %s not covered" % corner)


func test_camera_follows_player_over_island() -> void:
	var game := _enter()
	await wait_physics_frames(2)
	assert_true(game.player().camera().is_current())
	assert_eq(game.get_viewport().get_camera_2d(), game.player().camera())


func test_chunk_collision_matches_obstacles() -> void:
	var game := _enter()
	var chunk := game.island_view().chunk_node(game.island.chunk_of(game.island.spawn()))
	var rect := game.island.chunk_rect(chunk.chunk)
	var blocked_area := 0.0
	var expected := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if game.island.is_blocked(Vector2i(x, y)):
				expected += 1
	for col in chunk.collision_shapes():
		var size: Vector2 = col.shape.size
		blocked_area += size.x * size.y
	var t := float(game.island_view().tile_px())
	assert_gt(expected, 0)
	assert_almost_eq(blocked_area / (t * t), float(expected), 0.001, "collision covers exactly the obstacle cells")


# --- 나무 · 돌 · 광물에 막힌다 ---

func test_blocked_by_tree_stone_ore_in_every_direction() -> void:
	var game := _enter()
	var view := game.island_view()
	var half := _half_body(game.player())
	var names := {IslandConfig.Deposit.TREE: "tree", IslandConfig.Deposit.STONE: "stone", IslandConfig.Deposit.IRON: "iron"}
	for deposit in names:
		for action in DIRS:
			var d: Vector2i = DIRS[action]
			var target := _find_target(game.island, deposit, d)
			var label := "%s %s" % [names[deposit], action]
			assert_ne(target, Vector2i(-1, -1), "no %s to test" % label)
			if target == Vector2i(-1, -1):
				continue
			await _teleport(game, target - d * 2)
			var moved := await _walk(game, action, 40)
			var dv := Vector2(d)
			var lead := game.player().global_position + dv * half
			var face := view.cell_center(target) - dv * (view.tile_px() / 2.0)
			assert_gt(moved, 8.0, "%s: player did not walk" % label)
			assert_lte(lead.dot(dv) - face.dot(dv), 0.5, "%s: walked into obstacle" % label)
			assert_ne(view.world_to_cell(game.player().global_position), target, label)


func test_free_ground_is_walkable() -> void:
	var game := _enter()
	# 스폰 7×7 빈터 안에서는 막힘 없이 걷는다.
	await _teleport(game, game.island.spawn() + Vector2i(-3, 0))
	var moved := await _walk(game, InputActions.MOVE_RIGHT, 20)
	var expected := MovementTuning.load_default().move_speed * 20.0 / Engine.physics_ticks_per_second
	assert_almost_eq(moved, expected, expected * 0.2)


func test_island_edge_blocks() -> void:
	var game := _enter()
	var map := game.island
	# 섬 가장자리는 바다라 원래 막힌다 — 바다를 빼면 벽만 남는지 본다. 바다가 막는 건 test_island_cliffs_game.gd.
	var row := -1
	for y in range(map.size):
		if map.deposit_at(Vector2i(0, y)) == IslandConfig.Deposit.NONE \
				and map.deposit_at(Vector2i(1, y)) == IslandConfig.Deposit.NONE:
			row = y
			break
	assert_gt(row, -1)
	# 가장자리 덩어리의 바다 충돌을 걷어 내고, 섬 밖 벽만으로 막히는지.
	await _teleport(game, Vector2i(1, row))
	var edge := game.island_view().chunk_node(map.chunk_of(Vector2i(0, row)))
	for col in edge.collision_shapes():
		col.disabled = true
	await wait_physics_frames(2)
	var moved := await _walk(game, InputActions.MOVE_LEFT, 40)
	assert_gt(moved, 8.0)
	assert_gte(game.player().global_position.x - _half_body(game.player()).x, -0.5, "walked off the island")


# --- 보이는 곳 위주로 만든다 · 들어가는 시간 ---

func test_entering_256_island_is_quick_and_builds_only_near_view() -> void:
	_select_world(SEED)
	var started := Time.get_ticks_usec()
	var game: GameScene = add_child_autofree((load(GAME) as PackedScene).instantiate())
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	gut.p("entering 256x256 island: %.1f ms (game _ready %.1f ms)" % [ms, game.load_usec / 1000.0])
	assert_eq(game.island.size, 256)
	assert_lt(ms, LOAD_LIMIT_MS, "entering took too long")
	assert_gt(game.load_usec, 0)
	assert_lt(game.island.built_chunks(), game.island.total_chunks() / 4, "built far more than the visible area")


func test_walking_far_builds_new_chunks_and_frees_old_ones() -> void:
	var game := _enter()
	var view := game.island_view()
	var start_chunk := game.island.chunk_of(game.island.spawn())
	var count := view.chunk_count()
	await _teleport(game, Vector2i(5, 5))
	assert_not_null(view.chunk_node(Vector2i.ZERO), "chunk at new place not built")
	assert_null(view.chunk_node(start_chunk), "far chunk kept")
	await wait_physics_frames(1)
	assert_lte(view.chunk_count(), count + 8, "chunk nodes keep piling up")
	assert_eq(view.get_children().filter(func(n): return n is IslandChunk).size(), view.chunk_count())


func test_lazy_map_equals_full_map_in_any_order() -> void:
	var full := IslandGenerator.generate(SEED)
	var lazy := IslandMap.new(IslandGenerator.new(SEED), true)
	assert_eq(lazy.built_chunks(), 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 500:
		var c := Vector2i(rng.randi_range(0, 255), rng.randi_range(0, 255))
		assert_eq(lazy.deposit_at(c), full.deposit_at(c))
		assert_eq(lazy.terrain_at(c), full.terrain_at(c))
	assert_eq(lazy.deposit_bytes(), full.deposit_bytes())
	assert_eq(lazy.terrain_bytes(), full.terrain_bytes())
	assert_eq(lazy.built_chunks(), lazy.total_chunks())
