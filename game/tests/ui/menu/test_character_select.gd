extends GutTest
## G-002 3단계 — 캐릭터 선택 (슬롯 3개) 수용 기준.

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_select_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	Screens.last_request = ""


func after_each() -> void:
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


func _save(slot: int, char_name: String) -> void:
	var c := CharacterData.new()
	c.name = char_name
	assert_eq(Session.store.save_character(slot, c), OK)


func _open() -> Control:
	var scene := (load(Screens.CHARACTER_SELECT) as PackedScene).instantiate()
	return add_child_autofree(scene)


func _press(button: Button) -> void:
	assert_not_null(button)
	assert_true(button.is_visible_in_tree(), "%s not visible" % button.get_path())
	button.pressed.emit()


# --- 슬롯 3칸: 저장된 칸은 이름, 빈 칸은 「새 캐릭터」 ---

func test_three_slots() -> void:
	var screen := _open()
	assert_eq(SaveConfig.CHARACTER_SLOTS, 3)
	assert_eq(screen.get_node("%Slots").get_child_count(), 3)
	for slot in 3:
		assert_true(screen.slot_button(slot).is_visible_in_tree(), "slot %d hidden" % slot)


func test_filled_slot_shows_name_empty_slot_shows_new() -> void:
	_save(1, "나루")
	var screen := _open()
	assert_eq(screen.slot_button(0).text, "CHARACTER_NEW")
	assert_eq(screen.slot_button(1).text, "나루")
	assert_eq(screen.slot_button(2).text, "CHARACTER_NEW")


func test_slot_text_in_each_language() -> void:
	_save(0, "Tuna")
	var screen := _open()
	var saved := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	assert_eq(screen.slot_button(1).atr(screen.slot_button(1).text), "새 캐릭터")
	TranslationServer.set_locale("en")
	assert_eq(screen.slot_button(1).atr(screen.slot_button(1).text), "New Character")
	# 이름은 번역하지 않는다.
	assert_eq(screen.slot_button(0).auto_translate_mode, Node.AUTO_TRANSLATE_MODE_DISABLED)
	TranslationServer.set_locale(saved)


# --- 빈 칸 → 생성, 찬 칸 → 그 캐릭터를 들고 월드 선택 ---

func test_empty_slot_goes_to_character_create() -> void:
	_save(0, "A")
	_press(_open().slot_button(2))
	assert_eq(Screens.last_request, Screens.CHARACTER_CREATE)
	assert_eq(Session.character_slot, 2)
	assert_null(Session.character)


func test_filled_slot_goes_to_world_select_with_character() -> void:
	_save(0, "A")
	_save(2, "C")
	_press(_open().slot_button(2))
	assert_eq(Screens.last_request, Screens.WORLD_SELECT)
	assert_eq(Session.character_slot, 2)
	assert_not_null(Session.character)
	if Session.character:
		assert_eq(Session.character.name, "C")


# --- 삭제는 확인을 한 번 거친다 ---

func test_delete_button_only_on_filled_slots() -> void:
	_save(1, "B")
	var screen := _open()
	assert_false(screen.delete_button(0).is_visible_in_tree())
	assert_true(screen.delete_button(1).is_visible_in_tree())
	assert_false(screen.delete_button(2).is_visible_in_tree())


func test_delete_asks_first_and_cancel_keeps_character() -> void:
	_save(1, "B")
	var screen := _open()
	var confirm: Control = screen.get_node("%Confirm")
	assert_false(confirm.visible)
	_press(screen.delete_button(1))
	assert_true(confirm.is_visible_in_tree(), "confirm not shown")
	assert_true(Session.store.has_character(1), "deleted before confirm")
	_press(screen.get_node("%ConfirmNo"))
	assert_false(confirm.visible)
	assert_true(Session.store.has_character(1))
	assert_eq(screen.slot_button(1).text, "B")
	assert_eq(Screens.last_request, "")


func test_confirmed_delete_empties_slot() -> void:
	_save(0, "A")
	_save(1, "B")
	var screen := _open()
	_press(screen.delete_button(1))
	_press(screen.get_node("%ConfirmYes"))
	assert_false(Session.store.has_character(1))
	assert_true(Session.store.has_character(0), "other slot must stay")
	assert_false(screen.get_node("%Confirm").visible)
	assert_eq(screen.slot_button(1).text, "CHARACTER_NEW")
	assert_false(screen.delete_button(1).is_visible_in_tree())
	assert_eq(screen.slot_button(0).text, "A")
	# 빈 칸이 됐으니 누르면 생성 화면으로 간다.
	_press(screen.slot_button(1))
	assert_eq(Screens.last_request, Screens.CHARACTER_CREATE)


# --- 뒤로 → 메인 화면 ---

func test_back_goes_to_main_menu() -> void:
	_press(_open().get_node("%Back"))
	assert_eq(Screens.last_request, Screens.MAIN_MENU)
