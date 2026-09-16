extends GutTest
## G-012 1단계 — 메뉴 화면(캐릭터 선택 · 캐릭터 생성 · 월드 선택 · 설정)에서 Esc → 뒤로.
## 글자 입력칸에 포커스가 있어도 뒤로 간다.

var _root := ""
var _gut_layer: CanvasLayer


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_menu_esc_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	Screens.last_request = ""
	# GUT 실행 화면이 입력칸보다 먼저 키를 받지 않게 숨긴다.
	_gut_layer = get_tree().root.get_node_or_null("GutRunner/GutLayer") as CanvasLayer
	if _gut_layer:
		_gut_layer.visible = false


func after_each() -> void:
	if _gut_layer:
		_gut_layer.visible = true
	Input.action_release(InputActions.MENU_EXIT)
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


func _open(path: String) -> Control:
	var screen: Control = add_child_autofree((load(path) as PackedScene).instantiate())
	await wait_process_frames(1)
	return screen


func _esc() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_ESCAPE
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_process_frames(1)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await wait_process_frames(1)


func _save_character(slot: int) -> void:
	var c := CharacterData.new()
	c.name = "A"
	assert_eq(Session.store.save_character(slot, c), OK)


func test_settings_escape_goes_to_main_menu() -> void:
	await _open(Screens.SETTINGS)
	await _esc()
	assert_eq(Screens.last_request, Screens.MAIN_MENU)


func test_character_select_escape_goes_to_main_menu() -> void:
	await _open(Screens.CHARACTER_SELECT)
	await _esc()
	assert_eq(Screens.last_request, Screens.MAIN_MENU)


func test_character_select_escape_closes_delete_confirm_first() -> void:
	_save_character(0)
	var screen := await _open(Screens.CHARACTER_SELECT)
	screen.delete_button(0).pressed.emit()
	assert_true(screen.get_node("%Confirm").visible, "setup: confirm shown")
	await _esc()
	assert_false(screen.get_node("%Confirm").visible, "Esc closes the confirm")
	assert_eq(Screens.last_request, "", "Esc on the confirm stays on the screen")
	assert_true(Session.store.has_character(0), "Esc does not delete")
	await _esc()
	assert_eq(Screens.last_request, Screens.MAIN_MENU)


func test_character_create_escape_goes_back_without_saving() -> void:
	Session.select_character(1)
	var screen := await _open(Screens.CHARACTER_CREATE)
	screen.get_node("%NameEdit").text = "B"
	assert_true(screen.get_node("%NameEdit").has_focus(), "setup: name field has focus")
	await _esc()
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)
	assert_false(Session.store.has_character(1), "Esc must not create the character")


func test_world_select_escape_goes_to_character_select() -> void:
	_save_character(0)
	Session.select_character(0)
	var screen := await _open(Screens.WORLD_SELECT)
	assert_true(screen.get_node("%NameEdit").has_focus(), "setup: name field has focus")
	await _esc()
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)


func test_world_select_escape_closes_delete_confirm_first() -> void:
	_save_character(0)
	Session.select_character(0)
	var id := Session.store.create_world(WorldData.create("X", 1))
	var screen := await _open(Screens.WORLD_SELECT)
	screen.delete_button(id).pressed.emit()
	assert_true(screen.get_node("%Confirm").visible, "setup: confirm shown")
	await _esc()
	assert_false(screen.get_node("%Confirm").visible, "Esc closes the confirm")
	assert_eq(Screens.last_request, "")
	assert_true(Session.store.has_world(id), "Esc does not delete")
	await _esc()
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)
