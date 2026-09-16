extends "res://tests/craft/stations/station_test_base.gd"
## G-012 설정 창 테스트 공용 — Esc 누르기 · 설정 창 찾기 · 버튼 누르기.

const MENU_ITEMS := ["Continue", "Settings", "WorldSettings", "MainMenu", "Quit"]


func after_each() -> void:
	for action in [InputActions.MENU_EXIT, InputActions.INVENTORY, InputActions.MOVE_RIGHT]:
		Input.action_release(action)
	Session.is_host = true
	super.after_each()


func _tap_key(keycode: Key) -> void:
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


func _esc() -> void:
	await _tap_key(KEY_ESCAPE)


func _menu(game: GameScene) -> GameMenu:
	return game.game_menu()


func _press(button: Button) -> void:
	assert_true(button.is_visible_in_tree(), "%s must be visible to press" % button.name)
	button.pressed.emit()
