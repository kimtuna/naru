extends GutTest
## G-004 채취 테스트가 함께 쓰는 준비 — 임시 저장소에 캐릭터 하나 · 월드 하나를 두고 게임 씬에 들어간다.
## 파일 이름이 test_ 로 시작하지 않아 혼자서는 돌지 않는다.

const Deposit := IslandConfig.Deposit
const AXE := {"id": "axe", "count": 1}
const PICKAXE := {"id": "pickaxe", "count": 1}

var _root := ""
var _world_id := ""
## 들어간 게임 씬 — 테스트가 끝나면 바로 지운다. 한 프레임 늦게 지워지면 다음 테스트 동안 커서를 읽는다.
var _games: Array[Node] = []
var _gut_layer: CanvasLayer


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_harvest_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	Screens.last_request = ""
	Pointer.clear_simulation()
	var c := CharacterData.new()
	c.name = "A"
	assert_eq(Session.store.save_character(0, c), OK)
	_world_id = Session.store.create_world(WorldData.create("X", world_seed()))


func after_each() -> void:
	for game in _games:
		if is_instance_valid(game):
			game.free()
	_games.clear()
	if _gut_layer:
		_gut_layer.visible = true
		_gut_layer = null
	Input.action_release(InputActions.USE)
	Input.action_release(InputActions.INTERACT)
	Pointer.clear_simulation()
	Screens.simulate = false
	Session.store = SaveStore.new()
	Session.clear()
	_remove_tree(_root)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for dir in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(dir))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _enter() -> GameScene:
	Session.select_character(0)
	Session.select_world(_world_id)
	var game: GameScene = (load(Screens.GAME) as PackedScene).instantiate()
	add_child(game)
	_games.append(game)
	return game


## 월드 시드 — 파일마다 바꿔 쓴다.
func world_seed() -> int:
	return 12345


func _cfg() -> HarvestConfig:
	return HarvestConfig.load_default()


func _swing_cfg() -> SwingConfig:
	return SwingConfig.load_default()


## 스폰 둘레에서 이 자원이 있는 칸과, 그 옆의 빈 칸(설 자리)을 찾는다. skip 에 든 칸은 건너뛴다.
func _find(game: GameScene, deposit: Deposit, skip: Array = []) -> Array:
	return _find_in(game.island, deposit, skip)


func _find_in(map: IslandMap, deposit: Deposit, skip: Array = []) -> Array:
	var s := map.spawn()
	for r in range(1, 60):
		for y in range(s.y - r, s.y + r + 1):
			for x in range(s.x - r, s.x + r + 1):
				var cell := Vector2i(x, y)
				if cell in skip or not map.has_cell(cell) or map.deposit_at(cell) != deposit:
					continue
				for n in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if map.has_cell(cell + n) and map.deposit_at(cell + n) == Deposit.NONE:
						return [cell, cell + n]
	fail_test("no %s near spawn" % deposit)
	return [Vector2i.ZERO, Vector2i.ZERO]


func _stand(game: GameScene, cell: Vector2i) -> void:
	game.player().global_position = game.island_view().cell_center(cell)
	game.island_view().update_around(game.player().global_position)


func _hold(game: GameScene, item: Variant) -> void:
	game.player().hotbar.set_item(3, item)
	game.player().hotbar.select(3)


## 칸이 빌 때까지 휘두르고 휘두른 횟수. 동작이 없으면 -1.
func _swings_to_clear(game: GameScene, cell: Vector2i) -> int:
	for i in range(1, 20):
		if not game.harvester().swing(cell):
			return -1
		if game.island.deposit_at(cell) == Deposit.NONE:
			return i
	return 99


## 물리 프레임 안에서 테스트가 끝나면 다음 테스트가 그 프레임 안에서 시작된다 — 일반 프레임으로 넘기고 끝낸다.
func _leave_physics_frame() -> void:
	await wait_process_frames(1)


func _drops_at(game: GameScene, cell: Vector2i) -> Array:
	var center := game.island_view().cell_center(cell)
	return game.dropped_items().filter(func(d): return d.position.is_equal_approx(center))


func _click(pressed: bool, at: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = at
	ev.global_position = at
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


## GUT 실행 화면이 헤드리스 창 전체를 덮어 클릭을 가져간다 — 클릭 테스트 동안만 숨긴다 (게임에는 없는 층).
func _hide_gut_layer() -> void:
	var layer := get_tree().root.get_node_or_null("GutRunner/GutLayer") as CanvasLayer
	if layer:
		layer.visible = false
		_gut_layer = layer
