extends "res://tests/craft/stations/station_test_base.gd"
## G-011 2단계 — 우클릭 상호작용: 손에 든 아이템이 자기 우클릭 동작을 가질 수 있고 (삽 · 씨앗 · 음식 자리),
## 겨눈 곳에 상호작용 오브젝트(제작대)가 있으면 그쪽이 먼저다.

const SEED := {"id": "test_seed", "count": 3}

var _calls: Array = []


func before_each() -> void:
	super.before_each()
	_calls.clear()


func _record(item: Dictionary, cell: Vector2i) -> bool:
	_calls.append([item.duplicate(), cell])
	return true


func test_held_item_action_runs_on_right_click() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	game.interactor().set_item_action(SEED.id, _record)
	_hold(game, SEED)
	var cell := here + Vector2i.RIGHT
	await _right_click_cell(game, cell)
	assert_eq(_calls, [[SEED, cell]], "the held item's own right-click action gets the aimed cell")
	assert_eq(game.swinger().swing_count, 0, "a right click is not a swing")
	await _leave_physics_frame()


func test_item_action_only_for_that_item() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	game.interactor().set_item_action(SEED.id, _record)
	for item in [AXE, null, {"id": "wood", "count": 2}]:
		_hold(game, item)
		await _right_click_cell(game, here + Vector2i.RIGHT)
	assert_eq(_calls, [], "other items and the bare hand do not use the seed action")
	await _leave_physics_frame()


func test_left_click_does_not_run_item_action() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	game.interactor().set_item_action(SEED.id, _record)
	_hold(game, SEED)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(here + Vector2i.RIGHT))
	_click(true, screen_mid)
	await wait_physics_frames(2)
	_click(false, screen_mid)
	await wait_physics_frames(1)
	assert_eq(_calls, [], "left click swings, it does not use the item")
	assert_gt(game.swinger().swing_count, 0)
	await _leave_physics_frame()


func test_aimed_station_comes_before_item_action() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	game.interactor().set_item_action(SEED.id, _record)
	_hold(game, SEED)
	await _right_click_cell(game, cell)
	assert_true(game.crafting_view().is_open(), "the station under the cursor opens")
	assert_eq(_calls, [], "the item action does not run when an object is aimed at")
	assert_eq(_held(game), SEED)
	await _leave_physics_frame()


func test_item_action_runs_next_to_out_of_reach_station() -> void:
	# 닿지 않는 제작대는 열리지 않으니 든 아이템의 동작으로 넘어간다.
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	_stand(game, cell + Vector2i(3, 0))
	game.interactor().set_item_action(SEED.id, _record)
	_hold(game, SEED)
	await _right_click_cell(game, cell)
	assert_false(game.crafting_view().is_open())
	assert_eq(_calls, [[SEED, cell]])
	await _leave_physics_frame()


func test_nothing_happens_while_bag_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	game.interactor().set_item_action(SEED.id, _record)
	_hold(game, SEED)
	game.inventory_view().set_open(true)
	await _right_click_cell(game, cell)
	await _right_click_cell(game, cell + Vector2i.DOWN)
	assert_false(game.crafting_view().is_open(), "right click does not open while the bag is open")
	assert_eq(_calls, [], "right click does not use the item while the bag is open")
	await _leave_physics_frame()


func test_item_handlers_are_asked_in_order_and_id_action_wins() -> void:
	# 종류로 고르는 동작(설치물 등)은 차례로 묻고, 처음 한 것에서 멈춘다. id 로 붙인 동작이 먼저다.
	Pointer.simulate(Vector2.ZERO)
	var interactor := Interactor.new()
	var player: Player = (load("res://player/player.tscn") as PackedScene).instantiate()
	add_child_autofree(player)
	add_child_autofree(interactor)
	interactor.player = player
	var asked: Array[String] = []
	for step in [["a", false], ["b", true], ["c", true]]:
		interactor.add_item_handler(func(_i: Dictionary, _c: Vector2i) -> bool:
			asked.append(step[0])
			return step[1])
	player.hotbar.set_item(1, {"id": "stone", "count": 1})
	player.hotbar.select(1)
	assert_true(interactor.interact(Vector2i(2, 2)))
	assert_eq(asked, ["a", "b"] as Array[String])
	asked.clear()
	interactor.set_item_action("stone", _record)
	assert_true(interactor.interact(Vector2i(2, 2)))
	assert_eq(asked, [] as Array[String], "the item's own action is used instead")
	assert_eq(_calls, [[{"id": "stone", "count": 1}, Vector2i(2, 2)]])
	player.hotbar.set_item(1, null)
	assert_false(interactor.interact(Vector2i(2, 2)), "bare hand has no right-click action here")
