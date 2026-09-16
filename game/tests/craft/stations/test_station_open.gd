extends "res://tests/craft/stations/station_test_base.gd"
## G-006 2단계 — 손이 닿는 거리에서 제작대를 좌클릭하면 도구 동작 대신 제작 화면이 열린다.


func _workbench_recipes() -> PackedStringArray:
	var out := PackedStringArray()
	for r in RecipeBook.load_default().recipes_at(WORKBENCH):
		out.append(r.id)
	return out


func test_click_on_station_in_reach_opens_crafting_instead_of_swinging() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	assert_false(game.crafting_view().is_open(), "placing does not open the screen")
	_hold(game, AXE)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(cell))
	_click(true, screen_mid)
	await wait_physics_frames(1)
	# 버튼을 쥔 채로 본다 — 떼고 나면 Swinger 는 입력을 받았어도 is_holding() 이 false 가 된다.
	assert_false(game.swinger().is_holding(), "the axe must not swing when the click opens the station")
	assert_true(game.crafting_view().is_open(), "click on a reachable station opens the crafting screen")
	_click(false, screen_mid)
	await wait_physics_frames(1)
	assert_true(game.crafting_view().visible)
	assert_same(game.crafting_view().station, game.stations().station_at(cell))
	assert_eq(game.crafting_view().shown_recipes(), _workbench_recipes())
	assert_eq(game.crafting_view().get_node("%Title").text, "STATION_WORKBENCH")
	await _leave_physics_frame()


func test_click_that_opens_station_never_reaches_the_tool() -> void:
	# 제작대를 누른 채 화면이 닫히고 커서가 나무로 옮겨가도, 그 누름은 도구에 가지 않았으니 나무를 치지 않는다.
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	var spot := _free_neighbor(game, found[1], [found[0]])
	game.stations().add_station(WORKBENCH, spot)
	_hold(game, AXE)
	assert_true(game.harvester().can_reach(found[0]), "setup: the tree is in reach")
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(spot))
	_click(true, screen_mid)
	await wait_physics_frames(1)
	assert_true(game.crafting_view().is_open(), "setup: the press opened the station")
	game.crafting_view().close()
	Pointer.simulate(game.island_view().cell_center(found[0]))
	await wait_physics_frames(5)
	assert_false(game.swinger().is_holding(), "the press eaten by the station stays away from the tool")
	assert_eq(game.harvester().progress_at(found[0]), 0, "the tree under the cursor is not hit")
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)
	_click(false, screen_mid)
	await _leave_physics_frame()


func test_tool_still_swings_when_click_is_not_on_station() -> void:
	# 대조: 같은 클릭이 제작대 밖이면 도구 동작(쥐고 휘두르기)으로 간다.
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, AXE)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(here + Vector2i.RIGHT))
	_click(true, screen_mid)
	await wait_physics_frames(1)
	assert_true(game.swinger().is_holding(), "a click elsewhere reaches the tool")
	_click(false, screen_mid)
	assert_false(game.crafting_view().is_open())
	await _leave_physics_frame()


func test_click_with_workbench_in_hand_opens_existing_station() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	_hold(game, _bench())
	await _click_cell(game, cell)
	assert_true(game.crafting_view().is_open(), "opening comes before placing")
	assert_eq(game.stations().all().size(), 1)
	assert_eq(_held(game), _bench(1))
	await _leave_physics_frame()


func test_station_out_of_reach_does_not_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	_stand(game, cell + Vector2i(3, 0))
	_hold(game, AXE)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(cell))
	_click(true, screen_mid)
	await wait_physics_frames(1)
	assert_false(game.crafting_view().is_open(), "a station out of reach does not open")
	assert_true(game.swinger().is_holding(), "the click goes to the tool as usual")
	_click(false, screen_mid)
	await _leave_physics_frame()


func test_escape_closes_crafting_without_leaving_game() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	await _click_cell(game, cell)
	assert_true(game.crafting_view().is_open())
	_press_action(&"menu_exit")
	await wait_process_frames(1)
	assert_false(game.crafting_view().is_open(), "Esc closes the crafting screen")
	assert_eq(Screens.last_request, "", "Esc on the open screen must not leave the game")
	assert_null(game.crafting_view().station)
	await _leave_physics_frame()


func test_clicks_do_not_swing_while_crafting_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	var spot := _free_neighbor(game, found[1], [found[0]])
	var station := game.stations().add_station(WORKBENCH, spot)
	_hold(game, AXE)
	await _click_cell(game, spot)
	assert_true(game.crafting_view().is_open(), "setup: screen opened")
	# 제작 화면이 열려 있는 동안 나무를 눌러도 휘두르지 않는다 (가방과 같은 규칙).
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(found[0]))
	_click(true, screen_mid)
	await wait_physics_frames(3)
	_click(false, screen_mid)
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE, "no swing while crafting is open")
	assert_same(game.crafting_view().station, station)
	await _leave_physics_frame()


## cell 둘레 8칸 가운데 자원 없는 칸 (skip 제외).
func _free_neighbor(game: GameScene, cell: Vector2i, skip: Array) -> Vector2i:
	for y in [-1, 0, 1]:
		for x in [-1, 0, 1]:
			var c := cell + Vector2i(x, y)
			if c != cell and not (c in skip) and game.stations().is_free(c):
				return c
	fail_test("no free cell next to " + str(cell))
	return cell


func test_walking_out_of_reach_closes_crafting() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	await _click_cell(game, cell)
	assert_true(game.crafting_view().is_open())
	_stand(game, cell + Vector2i(6, 0))
	await wait_physics_frames(2)
	assert_false(game.crafting_view().is_open(), "leaving reach closes the screen")
	await _leave_physics_frame()
