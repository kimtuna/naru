extends GutTest
## G-013 3단계 — 경사 이동 속력: 오르막 < 평지 < 내리막. 배율은 MovementTuning 한 곳에. 대각선도 같은 속력.

const GAME := "res://world/game.tscn"
const PLAYER_SCENE := "res://player/player.tscn"
const SEED := 20260916
const STEPS := 6
const DIRS := [
	[[InputActions.MOVE_RIGHT], Vector2(1, 0)],
	[[InputActions.MOVE_LEFT], Vector2(-1, 0)],
	[[InputActions.MOVE_DOWN], Vector2(0, 1)],
	[[InputActions.MOVE_UP], Vector2(0, -1)],
	[[InputActions.MOVE_UP, InputActions.MOVE_RIGHT], Vector2(1, -1)],
	[[InputActions.MOVE_UP, InputActions.MOVE_LEFT], Vector2(-1, -1)],
	[[InputActions.MOVE_DOWN, InputActions.MOVE_RIGHT], Vector2(1, 1)],
	[[InputActions.MOVE_DOWN, InputActions.MOVE_LEFT], Vector2(-1, 1)],
]

var _root := ""


func after_each() -> void:
	for d in DIRS:
		for a in d[0]:
			Input.action_release(a)
	Session.store = SaveStore.new()
	Session.clear()
	if _root != "":
		_remove_dir(_root)
		_root = ""


## 입력을 누른 채 실제 물리 루프에서 steps 걸음 걷고 속력 벡터(픽셀/초)를 돌려준다.
func _walk(p: Player, actions: Array, steps := 1) -> Vector2:
	for a in actions:
		Input.action_press(a)
	await get_tree().physics_frame
	var before := p.global_position
	for i in steps:
		await get_tree().physics_frame
	var moved := (p.global_position - before) * Engine.physics_ticks_per_second / steps
	for a in actions:
		Input.action_release(a)
	await get_tree().physics_frame
	return moved


# --- 플레이어 — 경사 배율이 속력에 곱해진다 (가짜 경사: 오른쪽이 오르막) ---

func _east_up(_pos: Vector2, dir: Vector2) -> int:
	return signi(roundi(dir.x * 10.0))


func test_uphill_slower_downhill_faster_than_flat() -> void:
	var p: Player = add_child_autofree((load(PLAYER_SCENE) as PackedScene).instantiate())
	p.slope = _east_up
	var base := p.tuning.move_speed
	var up: float = (await _walk(p, [InputActions.MOVE_RIGHT])).length()
	var flat: float = (await _walk(p, [InputActions.MOVE_DOWN])).length()
	var down: float = (await _walk(p, [InputActions.MOVE_LEFT])).length()
	assert_almost_eq(flat, base, 0.01, "flat speed is unchanged")
	assert_lt(up, flat, "uphill must be slower than flat")
	assert_gt(down, flat, "downhill must be faster than flat")
	assert_almost_eq(up, base * p.tuning.uphill_multiplier, 0.01)
	assert_almost_eq(down, base * p.tuning.downhill_multiplier, 0.01)


func test_diagonal_on_slope_keeps_speed_normalized() -> void:
	var p: Player = add_child_autofree((load(PLAYER_SCENE) as PackedScene).instantiate())
	p.slope = _east_up
	var up: float = (await _walk(p, [InputActions.MOVE_RIGHT])).length()
	var up_diag := await _walk(p, [InputActions.MOVE_UP, InputActions.MOVE_RIGHT])
	var down: float = (await _walk(p, [InputActions.MOVE_LEFT])).length()
	var down_diag := await _walk(p, [InputActions.MOVE_DOWN, InputActions.MOVE_LEFT])
	assert_almost_eq(up_diag.length(), up, 0.01, "diagonal uphill = straight uphill speed")
	assert_almost_eq(down_diag.length(), down, 0.01, "diagonal downhill = straight downhill speed")
	assert_almost_eq(up_diag.normalized().dot(Vector2(1, -1).normalized()), 1.0, 0.0001)
	assert_almost_eq(down_diag.normalized().dot(Vector2(-1, 1).normalized()), 1.0, 0.0001)


# --- 배율 값은 한 곳 ---

func test_multipliers_live_in_tuning_resource() -> void:
	var tuning := MovementTuning.load_default()
	assert_lt(tuning.uphill_multiplier, 1.0, "uphill multiplier slows down")
	assert_gt(tuning.uphill_multiplier, 0.0)
	assert_gt(tuning.downhill_multiplier, 1.0, "downhill multiplier speeds up")
	assert_eq(tuning.slope_multiplier(0), 1.0)
	for path in [PLAYER_SCENE, "res://player/player.gd", GAME, "res://world/game.gd",
			"res://world/island/island_view.gd"]:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("uphill_multiplier = ") or text.contains("downhill_multiplier = "),
			"%s must not set its own slope multiplier" % path)


func test_changing_tuning_changes_slope_speed() -> void:
	var p: Player = add_child_autofree((load(PLAYER_SCENE) as PackedScene).instantiate())
	p.slope = _east_up
	var custom := MovementTuning.new()
	custom.move_speed = 100.0
	custom.uphill_multiplier = 0.25
	custom.downhill_multiplier = 2.0
	p.tuning = custom
	assert_almost_eq((await _walk(p, [InputActions.MOVE_RIGHT])).length(), 25.0, 0.01)
	assert_almost_eq((await _walk(p, [InputActions.MOVE_LEFT])).length(), 200.0, 0.01)
	assert_almost_eq((await _walk(p, [InputActions.MOVE_UP, InputActions.MOVE_RIGHT])).length(), 25.0, 0.01)


# --- 실제 섬 — 산 경사를 오르내린다 ---

func _enter() -> GameScene:
	_root = OS.get_temp_dir().path_join("naru_test_slope_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	var ch := CharacterData.new()
	ch.name = "tester"
	assert_eq(Session.store.save_character(0, ch), OK)
	Session.select_character(0)
	Session.select_world(Session.store.create_world(WorldData.create("island", SEED)))
	return add_child_autofree((load(GAME) as PackedScene).instantiate())


## 3×3 둘레가 다 걸을 수 있고, dir 쪽으로 걷는 동안 계속 오르막인 칸. 없으면 (-1, -1).
func _uphill_cell(view: IslandView, dir: Vector2) -> Vector2i:
	var map := view.map
	var s := map.spawn()
	var travel := dir.normalized() * 12.0
	for r in range(2, 100):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := s + Vector2i(dx, dy)
				var at := view.cell_center(c)
				if view.slope_along(at, dir) != 1 or view.slope_along(at + travel, dir) != 1 \
						or view.slope_along(at, -dir) != -1 or view.slope_along(at - travel, -dir) != -1:
					continue
				if _clear_around(map, c):
					return c
	return Vector2i(-1, -1)


func _clear_around(map: IslandMap, c: Vector2i) -> bool:
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if map.is_blocked(c + Vector2i(ox, oy)):
				return false
	return true


func _stand(game: GameScene, cell: Vector2i) -> void:
	var p := game.player()
	p.global_position = game.island_view().cell_center(cell)
	p.velocity = Vector2.ZERO
	game.island_view().update_around(p.global_position)


func test_real_island_slope_speeds() -> void:
	var game := _enter()
	var view := game.island_view()
	var p := game.player()
	var base := p.tuning.move_speed
	var spawn := game.island.spawn()
	assert_eq(view.slope_along(view.cell_center(spawn), Vector2.RIGHT), 0, "spawn is flat")
	_stand(game, spawn)
	var flat: float = (await _walk(p, [InputActions.MOVE_RIGHT], STEPS)).length()
	assert_almost_eq(flat, base, 0.01, "flat ground keeps base speed")
	var straight_up := -1.0
	for d in DIRS:
		var dir: Vector2 = d[1]
		var cell := _uphill_cell(view, dir)
		assert_ne(cell, Vector2i(-1, -1), "no walkable uphill toward %s" % [dir])
		if cell == Vector2i(-1, -1):
			continue
		assert_gt(game.island.height_at(view.world_to_cell(view.cell_center(cell) + dir * 24.0)),
			game.island.height_at(view.world_to_cell(view.cell_center(cell) - dir * 24.0)),
			"ground really rises toward %s" % [dir])
		_stand(game, cell)
		var up := await _walk(p, d[0], STEPS)
		var opposite: Array = []
		for a in d[0]:
			opposite.append(_opposite(a))
		_stand(game, cell)
		var down := await _walk(p, opposite, STEPS)
		assert_lt(up.length(), flat, "uphill slower than flat toward %s" % [dir])
		assert_gt(down.length(), flat, "downhill faster than flat away from %s" % [dir])
		assert_almost_eq(up.length(), base * p.tuning.uphill_multiplier, 0.01, "uphill %s" % [dir])
		assert_almost_eq(down.length(), base * p.tuning.downhill_multiplier, 0.01, "downhill %s" % [dir])
		assert_almost_eq(up.normalized().dot(dir.normalized()), 1.0, 0.0001, "walked toward %s" % [dir])
		if straight_up < 0.0:
			straight_up = up.length()
		assert_almost_eq(up.length(), straight_up, 0.01, "diagonal uphill = straight uphill (%s)" % [dir])


func _opposite(action: StringName) -> StringName:
	match action:
		InputActions.MOVE_RIGHT:
			return InputActions.MOVE_LEFT
		InputActions.MOVE_LEFT:
			return InputActions.MOVE_RIGHT
		InputActions.MOVE_UP:
			return InputActions.MOVE_DOWN
	return InputActions.MOVE_UP


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
