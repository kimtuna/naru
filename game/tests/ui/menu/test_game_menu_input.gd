extends "res://tests/ui/menu/game_menu_test_base.gd"
## G-012 1단계 — 설정 창이 열려 있는 동안 클릭 · 이동 · 가방 키는 게임에 들어가지 않고, 월드 시간은 흐른다.


# --- 열려 있는 동안 클릭 · 이동은 게임에 들어가지 않고, 시간은 흐른다 ---

func test_left_click_does_not_swing_while_menu_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var corner := get_viewport().get_visible_rect().size - Vector2(2, 2)
	Pointer.simulate(game.island_view().cell_center(found[0]))
	await _esc()
	# 버튼이 없는 곳(구석)을 누른다 — 가운데는 설정 창 버튼이다.
	for at in [Vector2(2, 2), corner]:
		_click(true, at)
		await wait_physics_frames(3)
		assert_false(game.player().is_swing_shown(), "no swing while the menu is open")
		_click(false, at)
		await wait_physics_frames(1)
	assert_true(game.game_menu().is_open(), "clicks on empty space keep the menu open")
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE, "click must not swing while the menu is open")
	await _esc()
	_click(true, Vector2(2, 2))
	await wait_physics_frames(3)
	_click(false, Vector2(2, 2))
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "click swings again after closing")
	await _leave_physics_frame()


func test_right_click_does_not_interact_while_menu_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, _bench())
	var cell := here + Vector2i.RIGHT
	await _esc()
	await _right_click_cell(game, cell)
	assert_null(game.stations().station_at(cell), "right click must not place while the menu is open")
	assert_eq(_held(game), _bench(), "workbench stays in hand")
	await _esc()
	await _right_click_cell(game, cell)
	assert_not_null(game.stations().station_at(cell), "right click places again after closing")
	await _leave_physics_frame()


func test_movement_is_ignored_while_menu_is_open() -> void:
	var game := _enter()
	await _esc()
	var start := game.player().global_position
	Input.action_press(InputActions.MOVE_RIGHT)
	await wait_physics_frames(5)
	assert_eq(game.player().global_position, start, "player must not move while the menu is open")
	await _esc()
	await wait_physics_frames(5)
	Input.action_release(InputActions.MOVE_RIGHT)
	assert_gt(game.player().global_position.x, start.x, "player moves again after closing")
	await _leave_physics_frame()


func test_bag_key_does_not_open_bag_while_menu_is_open() -> void:
	var game := _enter()
	await _esc()
	await _tap_key(KEY_TAB)
	assert_false(game.inventory_view().is_open(), "bag stays closed under the menu")
	assert_true(_menu(game).is_open())


func test_world_time_keeps_flowing_while_menu_is_open() -> void:
	var game := _enter()
	game.clock().speed = 100.0
	await _esc()
	assert_true(_menu(game).is_open())
	var before := game.island.time
	await wait_process_frames(5)
	assert_gt(game.island.time, before, "world time flows while the menu is open")
	assert_false(get_tree().paused, "the tree is not paused")
