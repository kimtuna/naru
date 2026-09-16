extends GutTest
## G-003 1단계 · G-011 2단계 — 이동 · 좌클릭 · 우클릭 · 핫바 선택이 InputMap 액션이고, 코드는 키 코드가 아니라 액션 이름을 쓴다.

## 게임 코드에서 키 · 버튼을 직접 읽는 흔적.
const RAW_INPUT := "KEY_[A-Z0-9_]+|MOUSE_BUTTON_[A-Z_]+|keycode|is_key_pressed|is_mouse_button_pressed|InputEventKey|InputEventMouseButton"
const SKIP_DIRS := ["res://addons", "res://tests", "res://.godot"]


func after_each() -> void:
	for action in InputActions.all():
		Input.action_release(action)


func _key_event(physical: Key, pressed := true) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.pressed = pressed
	return ev


func _events_match(action: StringName, ev: InputEvent) -> bool:
	return InputMap.event_is_action(ev, action, true)


func test_all_actions_are_in_input_map() -> void:
	for action in InputActions.all():
		assert_true(InputMap.has_action(action), "InputMap missing action: " + action)
		if InputMap.has_action(action):
			assert_gt(InputMap.action_get_events(action).size(), 0, "no events bound: " + action)


func test_wasd_bound_to_move_actions() -> void:
	assert_true(_events_match(InputActions.MOVE_UP, _key_event(KEY_W)))
	assert_true(_events_match(InputActions.MOVE_LEFT, _key_event(KEY_A)))
	assert_true(_events_match(InputActions.MOVE_DOWN, _key_event(KEY_S)))
	assert_true(_events_match(InputActions.MOVE_RIGHT, _key_event(KEY_D)))
	assert_false(_events_match(InputActions.MOVE_UP, _key_event(KEY_S)))


func test_left_click_bound_to_use() -> void:
	var left := InputEventMouseButton.new()
	left.button_index = MOUSE_BUTTON_LEFT
	left.pressed = true
	assert_true(_events_match(InputActions.USE, left))
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	assert_false(_events_match(InputActions.USE, right), "right click must not be use")


func test_right_click_bound_to_interact() -> void:
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	assert_true(InputMap.has_action(InputActions.INTERACT), "interact is an InputMap action")
	assert_true(_events_match(InputActions.INTERACT, right), "right click is interact")
	var left := InputEventMouseButton.new()
	left.button_index = MOUSE_BUTTON_LEFT
	left.pressed = true
	assert_false(_events_match(InputActions.INTERACT, left), "left click must not be interact")


func test_simulated_right_click_reaches_interact_action() -> void:
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	Input.parse_input_event(right)
	Input.flush_buffered_events()
	assert_true(Input.is_action_pressed(InputActions.INTERACT))
	assert_false(Input.is_action_pressed(InputActions.USE))
	var release := right.duplicate() as InputEventMouseButton
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(InputActions.INTERACT))


func test_number_key_n_selects_hotbar_slot_n() -> void:
	var keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
	for i in keys.size():
		var slot := i + 1
		assert_eq(InputActions.hotbar_slot_pressed(_key_event(keys[i])), slot,
			"key %s should pick slot %d" % [OS.get_keycode_string(keys[i]), slot])
	assert_eq(InputActions.hotbar_slot_pressed(_key_event(KEY_W)), 0, "W is not a hotbar key")
	assert_eq(InputActions.hotbar_slot_pressed(_key_event(KEY_3, false)), 0, "release is not a press")


func test_move_vector_reads_actions_and_is_normalized() -> void:
	Input.action_press(InputActions.MOVE_RIGHT)
	assert_almost_eq(InputActions.move_vector(), Vector2.RIGHT, Vector2(0.001, 0.001))
	Input.action_press(InputActions.MOVE_UP)
	var diagonal := InputActions.move_vector()
	assert_almost_eq(diagonal.length(), 1.0, 0.001, "diagonal must be as long as straight")
	assert_gt(diagonal.x, 0.0)
	assert_lt(diagonal.y, 0.0)


func test_simulated_key_press_reaches_move_action() -> void:
	Input.parse_input_event(_key_event(KEY_A))
	Input.flush_buffered_events()
	assert_true(Input.is_action_pressed(InputActions.MOVE_LEFT))
	Input.parse_input_event(_key_event(KEY_A, false))
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(InputActions.MOVE_LEFT))


func test_game_code_uses_action_names_not_key_codes() -> void:
	var regex := RegEx.create_from_string(RAW_INPUT)
	var hits: Array[String] = []
	var files := _game_scripts("res://")
	assert_gt(files.size(), 0, "no game scripts found")
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n in lines.size():
			if regex.search(lines[n]):
				hits.append("%s:%d %s" % [path, n + 1, lines[n].strip_edges()])
	assert_eq(hits, [] as Array[String], "raw key/button use in game code:\n" + "\n".join(hits))


func _game_scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	if dir.trim_suffix("/") in SKIP_DIRS:
		return out
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_game_scripts(dir.path_join(sub)))
	return out
