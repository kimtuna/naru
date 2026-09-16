extends "res://tests/life/harvest/harvest_test_base.gd"
## G-004 4단계 — 가방 화면을 InputMap 액션으로 열고 닫는다. 칸 목록이 보이고, 열려 있는 동안 좌클릭은 휘두르지 않는다.


func after_each() -> void:
	Input.action_release(InputActions.INVENTORY)
	super.after_each()


func _tap_bag() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_TAB
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_process_frames(1)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await wait_process_frames(1)


func test_bag_action_is_in_input_map() -> void:
	assert_true(InputMap.has_action(InputActions.INVENTORY))
	assert_true(InputActions.INVENTORY in InputActions.all())
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_TAB
	ev.pressed = true
	assert_true(InputMap.event_is_action(ev, InputActions.INVENTORY, true))


func test_bag_key_opens_and_closes_the_slot_list() -> void:
	_hide_gut_layer()
	var game := _enter()
	var view := game.inventory_view()
	await wait_process_frames(1)
	assert_false(view.is_visible_in_tree(), "bag starts closed")
	await _tap_bag()
	assert_true(view.is_open())
	assert_true(view.is_visible_in_tree(), "bag must show after the bag key")
	assert_eq(view.slot_count(), InventoryConfig.BAG_SIZE)
	for i in view.slot_count():
		assert_true(view.slot(i).is_visible_in_tree(), "slot %d hidden" % i)
	assert_true(game.hotbar_view().is_visible_in_tree(), "hotbar stays while bag is open")
	await _tap_bag()
	assert_false(view.is_open())
	assert_false(view.is_visible_in_tree(), "bag must hide after the second press")
	await _tap_bag()
	assert_true(view.is_visible_in_tree(), "bag must open again")


func test_slot_list_shows_inventory_contents() -> void:
	var game := _enter()
	var view := game.inventory_view()
	var inv := game.player().hotbar.inventory
	inv.set_slot(0, {"id": "axe", "count": 1})
	inv.set_slot(InventoryConfig.BAG_SIZE - 1, {"id": "stone", "count": 12})
	view.set_open(true)
	assert_true(view.slot_has_item(0))
	assert_eq(view.slot_count_text(0), "")
	assert_true(view.slot_has_item(InventoryConfig.BAG_SIZE - 1))
	assert_eq(view.slot_count_text(InventoryConfig.BAG_SIZE - 1), "12")
	assert_false(view.slot_has_item(1))
	# 줍기로 들어온 것도 바로 보인다.
	inv.add({"id": "wood", "count": 3})
	assert_true(view.slot_has_item(1))
	assert_eq(view.slot_count_text(1), "3")


func test_left_click_does_not_swing_while_bag_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(found[0]))
	await _tap_bag()
	assert_true(game.inventory_view().is_open())
	_click(true, screen_mid)
	await wait_physics_frames(3)
	_click(false, screen_mid)
	await wait_physics_frames(1)
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE, "click must not swing while bag is open")
	await _tap_bag()
	_click(true, screen_mid)
	await wait_physics_frames(3)
	_click(false, screen_mid)
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "click swings again after closing")
	await _leave_physics_frame()


func test_holding_click_while_closing_bag_keeps_swinging() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(found[0]))
	await _tap_bag()
	_click(true, screen_mid)
	await wait_physics_frames(3)
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)
	await _tap_bag()
	await wait_physics_frames(3)
	_click(false, screen_mid)
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "held click continues after the bag closes")
	await _leave_physics_frame()
