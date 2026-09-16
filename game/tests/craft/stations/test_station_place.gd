extends "res://tests/craft/stations/station_test_base.gd"
## G-006 2단계 — 핫바에서 제작대를 들고 빈 칸에 좌클릭하면 설치된다. 막힌 칸에는 안 된다.


func test_left_click_with_workbench_places_on_empty_cell() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, _bench(2))
	var cell := here + Vector2i.RIGHT
	assert_null(game.stations().station_at(cell))
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(cell))
	_click(true, screen_mid)
	await wait_physics_frames(1)
	# 버튼을 쥔 채로 본다 — 떼고 나면 is_holding() 은 늘 false 다.
	assert_false(game.swinger().is_holding(), "placing is not a tool swing")
	_click(false, screen_mid)
	await wait_physics_frames(1)
	var station := game.stations().station_at(cell)
	assert_not_null(station, "click with a workbench in hand must place it on the empty cell")
	if station:
		assert_eq(station.station_id, WORKBENCH)
		assert_eq(station.cell, cell)
		assert_true(station.is_inside_tree())
		assert_eq(station.get_child_count(), 1, "the station blocks the body with one collision box")
		assert_true(station.get_child(0) is CollisionShape2D)
	assert_eq(_held(game), _bench(1), "placing uses one workbench from the held slot")
	assert_true(game.regrowth().structures.has(cell), "resources must not regrow around the station")
	await _leave_physics_frame()


func test_placing_the_last_one_empties_the_hand() -> void:
	_hide_gut_layer()
	var game := _enter()
	await _place_next_to_spawn(game)
	assert_null(_held(game), "the last workbench leaves the slot empty")
	assert_eq(game.player().hotbar.inventory.count_of(WORKBENCH), 0)
	await _leave_physics_frame()


func test_not_placed_on_resource_cell() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, _bench())
	await _click_cell(game, found[0])
	assert_null(game.stations().station_at(found[0]), "a tree cell is blocked")
	assert_eq(_held(game), _bench(1), "nothing is used on a blocked cell")
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)
	await _leave_physics_frame()


func test_not_placed_on_own_cell() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, _bench())
	await _click_cell(game, here)
	assert_null(game.stations().station_at(here), "the cell the body stands on is blocked")
	assert_eq(_held(game), _bench(1))
	await _leave_physics_frame()


func test_not_placed_on_existing_station() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	var first := game.stations().station_at(cell)
	_hold(game, _bench())
	# 실제 클릭은 여는 것이 먼저라 (test_station_open) 놓기만 따로 부른다.
	assert_false(game.stations().try_place(cell), "an occupied cell is blocked")
	assert_eq(game.stations().all().size(), 1)
	assert_same(game.stations().station_at(cell), first)
	assert_eq(_held(game), _bench(1))
	await _leave_physics_frame()


func test_not_placed_out_of_reach_or_off_island() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, _bench())
	var far := here + Vector2i(3, 0)
	assert_eq(game.island.deposit_at(far), Deposit.NONE, "setup: spawn clearing is empty")
	await _click_cell(game, far)
	assert_null(game.stations().station_at(far), "a cell out of reach is not used")
	assert_eq(_held(game), _bench(1))
	# 섬 가장자리에서 섬 밖 칸.
	_stand(game, Vector2i(0, 0))
	assert_false(game.stations().try_place(Vector2i(-1, 0)), "outside the island is blocked")
	assert_eq(game.stations().all().size(), 0)
	await _leave_physics_frame()


func test_other_items_are_not_placed() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, AXE)
	await _click_cell(game, here + Vector2i.RIGHT)
	assert_eq(game.stations().all().size(), 0, "an axe is not a station")
	_hold(game, {"id": "wood", "count": 5})
	await _click_cell(game, here + Vector2i.RIGHT)
	assert_eq(game.stations().all().size(), 0, "raw material is not a station")
	assert_eq(_held(game), {"id": "wood", "count": 5})
	await _leave_physics_frame()


func test_not_placed_while_bag_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, _bench())
	game.inventory_view().set_open(true)
	await _click_cell(game, here + Vector2i.RIGHT)
	assert_eq(game.stations().all().size(), 0, "clicks do nothing while the bag is open")
	assert_eq(_held(game), _bench(1))
	await _leave_physics_frame()


func test_placed_station_survives_saving() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	game.exit_to_menu()
	Screens.last_request = ""
	game.free()
	await wait_process_frames(1)
	var saved := Session.store.load_world(_world_id)
	assert_eq(saved.stations, [{"id": WORKBENCH, "cell": cell}])
	var again := _enter()
	var station := again.stations().station_at(cell)
	assert_not_null(station, "the station is back after re-entering")
	if station:
		assert_eq(station.station_id, WORKBENCH)
	assert_true(again.regrowth().structures.has(cell))
	await _leave_physics_frame()
