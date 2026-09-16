extends GutTest
## G-002 4단계 — 캐릭터 생성 · 커스터마이징 (칸만) 수용 기준.

const REQUIRED_PARTS := ["body", "hair_style", "hair_color", "outfit"]

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_create_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Session.select_character(1)
	Screens.simulate = true
	Screens.last_request = ""
	AppearanceCatalog.path = AppearanceCatalog.DEFAULT_PATH


func after_each() -> void:
	Screens.simulate = false
	Session.store = SaveStore.new()
	Session.clear()
	AppearanceCatalog.path = AppearanceCatalog.DEFAULT_PATH
	_remove_tree(_root)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for dir in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(dir))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _open(path: String = Screens.CHARACTER_CREATE) -> Control:
	return add_child_autofree((load(path) as PackedScene).instantiate())


func _press(button: Button) -> void:
	assert_not_null(button)
	if button:
		assert_true(button.is_visible_in_tree(), "%s not visible" % button.get_path())
		button.pressed.emit()


func _value(screen: Control, part_id: String) -> String:
	return (screen.part_row(part_id).get_node("Value") as Label).text


## 기본 데이터 파일을 읽어 고친 복사본을 임시 파일로 쓰고, 화면이 그것을 읽게 한다.
func _use_modified_catalog(edit: Callable) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(AppearanceCatalog.DEFAULT_PATH))
	edit.call(data)
	DirAccess.make_dir_recursive_absolute(_root)
	var path := _root.path_join("appearance.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	AppearanceCatalog.path = path


# --- 이름 입력칸 + 외형 항목 여러 개, 항목마다 이전/다음 ---

func test_name_field_and_required_parts_with_prev_next() -> void:
	var screen := _open()
	var name_edit := screen.get_node("%NameEdit") as LineEdit
	assert_not_null(name_edit)
	assert_true(name_edit.is_visible_in_tree())
	for id in REQUIRED_PARTS:
		var row: Control = screen.part_row(id)
		assert_not_null(row, "missing part " + id)
		if row == null:
			continue
		assert_true(row.is_visible_in_tree())
		assert_true((row.get_node("Prev") as Button).is_visible_in_tree())
		assert_true((row.get_node("Next") as Button).is_visible_in_tree())
		assert_ne(_value(screen, id), "")


func test_prev_next_cycle_options() -> void:
	var screen := _open()
	var data := screen.catalog.parts[0] as Dictionary
	var opts: Array = data.options
	assert_gt(opts.size(), 1, "need several options to switch")
	var row: Control = screen.part_row(data.id)
	assert_eq(_value(screen, data.id), opts[0].label)
	_press(row.get_node("Next"))
	assert_eq(_value(screen, data.id), opts[1].label)
	assert_eq(screen.appearance()[data.id], opts[1].id)
	_press(row.get_node("Prev"))
	assert_eq(_value(screen, data.id), opts[0].label)
	# 처음에서 이전 → 마지막으로 돈다.
	_press(row.get_node("Prev"))
	assert_eq(_value(screen, data.id), opts[opts.size() - 1].label)
	# 다른 항목은 그대로.
	var other: Dictionary = screen.catalog.parts[1]
	assert_eq(screen.appearance()[other.id], other.options[0].id)


# --- 항목 · 선택지는 데이터 파일 하나 — 파일만 고치면 화면에 나타난다 ---

func test_screen_parts_match_data_file() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(AppearanceCatalog.DEFAULT_PATH))
	var ids: Array = data.parts.map(func(p): return p.id)
	for id in REQUIRED_PARTS:
		assert_has(ids, id)
	var screen := _open()
	var rows: Array = screen.get_node("%Parts").get_children().map(func(n): return String(n.name))
	assert_eq(rows, ids)


func test_added_part_in_data_file_appears_on_screen() -> void:
	_use_modified_catalog(func(d):
		d.parts.append({"id": "hat", "label": "TEST_HAT", "options": [
			{"id": "hat_cap", "label": "TEST_CAP", "color": "#ff0000"},
			{"id": "hat_crown", "label": "TEST_CROWN", "color": "#00ff00"}]}))
	var screen := _open()
	var row: Control = screen.part_row("hat")
	assert_not_null(row, "added part not on screen")
	if row == null:
		return
	assert_eq((row.get_node("Label") as Label).text, "TEST_HAT")
	assert_eq(_value(screen, "hat"), "TEST_CAP")
	assert_eq(screen.preview_rect("hat").color, Color.html("#ff0000"))
	_press(row.get_node("Next"))
	assert_eq(_value(screen, "hat"), "TEST_CROWN")
	assert_eq(screen.preview_rect("hat").color, Color.html("#00ff00"))
	assert_eq(screen.appearance()["hat"], "hat_crown")
	for id in REQUIRED_PARTS:
		assert_not_null(screen.part_row(id))


func test_added_option_in_data_file_appears_on_screen() -> void:
	_use_modified_catalog(func(d):
		for p in d.parts:
			if p.id == "hair_color":
				p.options.append({"id": "hair_pink", "label": "TEST_PINK", "color": "#ff88cc"}))
	var screen := _open()
	var row: Control = screen.part_row("hair_color")
	_press(row.get_node("Prev"))  # 처음에서 이전 → 새로 넣은 마지막 선택지
	assert_eq(_value(screen, "hair_color"), "TEST_PINK")
	assert_eq(screen.preview_rect("hair_color").color, Color.html("#ff88cc"))


# --- 미리보기가 고른 선택지에 따라 바뀐다 ---

func test_preview_follows_choice() -> void:
	var screen := _open()
	for part in screen.catalog.parts:
		var rect: ColorRect = screen.preview_rect(part.id)
		assert_not_null(rect, "no preview for " + part.id)
		if rect == null:
			continue
		assert_true(rect.is_visible_in_tree())
		assert_eq(rect.color, part.options[0].color)
		var before := rect.color
		_press(screen.part_row(part.id).get_node("Next"))
		assert_eq(rect.color, part.options[1].color)
		assert_ne(rect.color, before, "preview did not change for " + part.id)


# --- 만들기 → 저장, 선택 화면의 그 칸에 나타난다 ---

func test_create_saves_to_chosen_slot_and_shows_in_select() -> void:
	var screen := _open()
	(screen.get_node("%NameEdit") as LineEdit).text = "  나루  "
	_press(screen.part_row("outfit").get_node("Next"))
	var expected: Dictionary = screen.appearance()
	_press(screen.get_node("%Create"))
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)
	assert_true(Session.store.has_character(1), "not saved to slot 1")
	assert_false(Session.store.has_character(0))
	var saved := Session.store.load_character(1)
	assert_not_null(saved)
	if saved:
		assert_eq(saved.name, "나루")
		assert_eq(saved.appearance, expected)
		assert_eq(saved.appearance["outfit"], screen.catalog.parts[3].options[1].id)
		# 새 캐릭터는 빈손.
		assert_eq(saved.inventory, [])
	var select := _open(Screens.CHARACTER_SELECT)
	assert_eq(select.slot_button(1).text, "나루")
	assert_eq(select.slot_button(0).text, "CHARACTER_NEW")


func test_empty_name_is_rejected() -> void:
	var screen := _open()
	var error := screen.get_node("%NameError") as Control
	assert_false(error.visible)
	for bad in ["", "   "]:
		(screen.get_node("%NameEdit") as LineEdit).text = bad
		_press(screen.get_node("%Create"))
		assert_true(error.is_visible_in_tree(), "no error for '%s'" % bad)
		assert_eq(Session.store.character_slots(), [] as Array[int])
		assert_eq(Screens.last_request, "")


func test_cancel_returns_without_saving() -> void:
	var screen := _open()
	(screen.get_node("%NameEdit") as LineEdit).text = "Tuna"
	_press(screen.get_node("%Cancel"))
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)
	assert_eq(Session.store.character_slots(), [] as Array[int])
	assert_false(DirAccess.dir_exists_absolute(_root.path_join(SaveConfig.CHARACTER_DIR)))


func test_new_character_inventory_is_empty() -> void:
	assert_eq(CharacterData.new().inventory, [])
	var screen := _open()
	(screen.get_node("%NameEdit") as LineEdit).text = "Empty"
	_press(screen.get_node("%Create"))
	var saved := Session.store.load_character(1)
	assert_not_null(saved)
	if saved:
		assert_true(saved.inventory.is_empty())


func test_labels_translate_in_each_language() -> void:
	var screen := _open()
	var label := screen.part_row("hair_color").get_node("Label") as Label
	var saved := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	assert_eq(label.atr(label.text), "머리 색")
	TranslationServer.set_locale("en")
	assert_eq(label.atr(label.text), "Hair Color")
	TranslationServer.set_locale(saved)
