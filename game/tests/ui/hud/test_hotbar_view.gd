extends GutTest
## G-003 4단계 — 게임 화면 아래 핫바가 항상 보이고, 숫자키로 고른 칸이 구분되고 손에 든 것이 되며, 저장 후에도 그대로.

var _root := ""
var _saved_size := Vector2i.ZERO


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_hotbar_view_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	Screens.last_request = ""
	# headless 창은 아주 작다 — 실제 창 기본 크기로 맞춰 화면 안 · 아래인지 본다.
	_saved_size = get_tree().root.size
	get_tree().root.size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))


func after_each() -> void:
	get_tree().root.size = _saved_size
	Screens.simulate = false
	Session.store = SaveStore.new()
	Session.clear()
	for n in range(1, InputActions.HOTBAR_ACTION_COUNT + 1):
		Input.action_release(InputActions.hotbar_action(n))
	Input.action_release(GameScene.EXIT_ACTION)
	_remove_tree(_root)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for dir in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(dir))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


## 캐릭터(인벤토리 포함)와 월드를 저장하고, 메뉴처럼 골라 게임 씬을 연다.
func _enter(inventory: Array = []) -> GameScene:
	if not Session.store.has_character(0):
		var c := CharacterData.new()
		c.name = "A"
		c.inventory = inventory
		Session.store.save_character(0, c)
	var ids := Session.store.world_ids()
	var id := ids[0] if ids.size() > 0 else Session.store.create_world(WorldData.create("X", 1))
	Session.select_character(0)
	Session.select_world(id)
	assert_true(Session.ready_to_play())
	return add_child_autofree((load(Screens.GAME) as PackedScene).instantiate())


func _tap(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_process_frames(1)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await wait_process_frames(1)


func test_hotbar_is_visible_at_bottom_of_screen() -> void:
	var game := _enter()
	await wait_process_frames(2)
	var view := game.hotbar_view()
	assert_not_null(view)
	assert_true(view.is_visible_in_tree(), "hotbar hidden")
	assert_eq(view.slot_count(), InventoryConfig.HOTBAR_SIZE)
	var screen := view.get_viewport_rect()
	assert_eq(Vector2i(screen.size), get_tree().root.size, "test screen size not applied")
	var rect := view.get_global_rect()
	assert_gt(rect.size.x, 0.0)
	assert_gt(rect.size.y, 0.0)
	assert_true(screen.encloses(rect), "hotbar %s not inside screen %s" % [rect, screen])
	assert_gt(rect.position.y, screen.size.y * 0.75, "hotbar not at the bottom")
	assert_almost_eq(rect.get_center().x, screen.get_center().x, 1.0, "hotbar not centered")
	for n in range(1, view.slot_count() + 1):
		assert_true(view.slot(n).is_visible_in_tree())
		assert_true(screen.encloses(view.slot(n).get_global_rect()), "slot %d off screen" % n)
	# 한 칸만 골라져 있고, 처음엔 1번.
	assert_true(view.is_slot_selected(1))
	for n in range(2, view.slot_count() + 1):
		assert_false(view.is_slot_selected(n))


func test_hotbar_stays_when_player_moves_away() -> void:
	var game := _enter()
	await wait_process_frames(1)
	var before := game.hotbar_view().get_global_rect()
	game.player().global_position = Vector2(400, 300)
	await wait_process_frames(2)
	assert_eq(game.hotbar_view().get_global_rect(), before)
	assert_true(game.hotbar_view().is_visible_in_tree())


func test_number_key_selects_slot_and_changes_held_item() -> void:
	var items := [{"id": "axe", "count": 1}, {"id": "pickaxe", "count": 1}, {"id": "stone", "count": 12}]
	var game := _enter(items)
	await wait_process_frames(1)
	var view := game.hotbar_view()
	assert_eq(game.player().held_item(), items[0])
	assert_true(view.slot_has_item(3))
	assert_eq((view.slot(3).get_node("Count") as Label).text, "12")
	assert_false(view.slot_has_item(4))

	await _tap(KEY_3)
	assert_eq(game.player().hotbar.selected(), 3)
	assert_eq(game.player().held_item(), items[2])
	assert_true(view.is_slot_selected(3))
	assert_false(view.is_slot_selected(1))

	await _tap(KEY_2)
	assert_eq(game.player().held_item(), items[1])
	assert_true(view.is_slot_selected(2))
	assert_false(view.is_slot_selected(3))

	await _tap(KEY_5)
	assert_eq(game.player().hotbar.selected(), 5)
	assert_null(game.player().held_item(), "empty slot must be empty hand")

	# 0 은 10번 칸.
	await _tap(KEY_0)
	assert_eq(game.player().hotbar.selected(), 10)
	assert_true(view.is_slot_selected(10))


func test_every_number_key_selects_its_slot() -> void:
	var game := _enter()
	await wait_process_frames(1)
	var keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
	for n in range(1, InventoryConfig.HOTBAR_SIZE + 1):
		await _tap(keys[n - 1])
		assert_eq(game.player().hotbar.selected(), n, "key for slot %d" % n)
		assert_true(game.hotbar_view().is_slot_selected(n))


func test_view_updates_when_item_is_put_in_hotbar() -> void:
	var game := _enter()
	await wait_process_frames(1)
	assert_false(game.hotbar_view().slot_has_item(1))
	game.player().hotbar.set_item(1, {"id": "wood", "count": 3})
	assert_true(game.hotbar_view().slot_has_item(1))
	assert_eq(game.player().held_item(), {"id": "wood", "count": 3})
	assert_eq(game.character.inventory[0], {"id": "wood", "count": 3}, "hotbar is not the character's inventory")


func test_hotbar_survives_exit_and_reenter() -> void:
	var game := _enter()
	await wait_process_frames(1)
	game.player().hotbar.set_item(2, {"id": "axe", "count": 1})
	game.player().hotbar.set_item(7, {"id": "seed", "count": 4})
	await _tap(KEY_7)
	await _tap(KEY_ESCAPE)
	assert_true(game.game_menu().is_open(), "Esc opens the game menu")
	game.game_menu().button("MainMenu").pressed.emit()
	assert_eq(Screens.last_request, Screens.MAIN_MENU)
	game.queue_free()
	await wait_process_frames(1)

	var again := _enter()
	await wait_process_frames(1)
	var bar := again.player().hotbar
	assert_eq(bar.selected(), 7)
	assert_eq(bar.held_item(), {"id": "seed", "count": 4})
	assert_eq(bar.item(2), {"id": "axe", "count": 1})
	assert_null(bar.item(1))
	assert_true(again.hotbar_view().is_slot_selected(7))
	assert_true(again.hotbar_view().slot_has_item(2))
