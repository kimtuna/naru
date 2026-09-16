extends GutTest
## G-002 5단계 — 월드 선택 · 생성 수용 기준.

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_world_%d_%d" % [Time.get_ticks_usec(), randi()])
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


func _character(slot: int, char_name: String) -> void:
	var c := CharacterData.new()
	c.name = char_name
	assert_eq(Session.store.save_character(slot, c), OK)
	Session.select_character(slot)


func _world(world_name: String, seed_value := 1) -> String:
	var id := Session.store.create_world(WorldData.create(world_name, seed_value))
	assert_ne(id, "")
	return id


func _open() -> Control:
	return add_child_autofree((load(Screens.WORLD_SELECT) as PackedScene).instantiate())


func _press(button: Button) -> void:
	assert_not_null(button)
	if button:
		assert_true(button.is_visible_in_tree(), "%s not visible" % button.get_path())
		button.pressed.emit()


func _names(screen: Control) -> Array:
	return Array(screen.listed_ids()).map(func(id): return screen.world_button(id).text)


# --- 저장된 월드 목록이 보인다 ---

func test_lists_saved_worlds() -> void:
	var a := _world("섬 A")
	var b := _world("Island B")
	var screen := _open()
	assert_eq(Array(screen.listed_ids()), [a, b])
	assert_eq(_names(screen), ["섬 A", "Island B"])
	for id in [a, b]:
		assert_true(screen.world_button(id).is_visible_in_tree())
		# 월드 이름은 번역하지 않는다.
		assert_eq(screen.world_button(id).auto_translate_mode, Node.AUTO_TRANSLATE_MODE_DISABLED)
	assert_false(screen.get_node("%Empty").visible)


func test_empty_list_says_so() -> void:
	var screen := _open()
	assert_eq(screen.listed_ids().size(), 0)
	assert_true(screen.get_node("%Empty").is_visible_in_tree())


# --- 새 월드 만들기: 이름 · 시드 ---

func test_create_with_name_and_seed() -> void:
	var screen := _open()
	screen.get_node("%NameEdit").text = "  새 섬 "
	screen.get_node("%SeedEdit").text = "12345"
	_press(screen.get_node("%Create"))
	var ids: PackedStringArray = Session.store.world_ids()
	assert_eq(ids.size(), 1)
	var w := Session.store.load_world(ids[0])
	assert_eq(w.name, "새 섬")
	assert_eq(w.world_seed, 12345)
	assert_eq(_names(screen), ["새 섬"], "new world must appear in the list")
	assert_eq(screen.get_node("%NameEdit").text, "")
	assert_eq(Screens.last_request, "", "creating alone must not enter the game")


func test_text_seed_is_stable() -> void:
	var script: GDScript = load("res://ui/menu/world_select.gd")
	assert_eq(script.seed_from_text("naru"), script.seed_from_text(" naru "))
	assert_ne(script.seed_from_text("naru"), script.seed_from_text("uran"))
	assert_eq(script.seed_from_text("-7"), -7)


func test_empty_seed_is_random() -> void:
	var screen := _open()
	var seeds := {}
	for i in 5:
		screen.get_node("%NameEdit").text = "W%d" % i
		screen.get_node("%SeedEdit").text = "   "
		var id: String = screen.create()
		assert_ne(id, "")
		seeds[Session.store.load_world(id).world_seed] = true
	assert_gt(seeds.size(), 1, "empty seed must pick random seeds")
	assert_eq(screen.listed_ids().size(), 5)


func test_create_needs_name() -> void:
	var screen := _open()
	screen.get_node("%NameEdit").text = "   "
	_press(screen.get_node("%Create"))
	assert_eq(Session.store.world_ids().size(), 0)
	assert_true(screen.get_node("%NameError").is_visible_in_tree())


# --- 삭제는 확인을 한 번 거친다 ---

func test_delete_asks_first_and_cancel_keeps_world() -> void:
	var a := _world("A")
	var screen := _open()
	_press(screen.delete_button(a))
	assert_true(screen.get_node("%Confirm").is_visible_in_tree(), "confirm not shown")
	assert_true(Session.store.has_world(a), "deleted before confirm")
	_press(screen.get_node("%ConfirmNo"))
	assert_false(screen.get_node("%Confirm").visible)
	assert_true(Session.store.has_world(a))
	assert_eq(Array(screen.listed_ids()), [a])


func test_confirmed_delete_removes_world() -> void:
	var a := _world("A")
	var b := _world("B")
	var screen := _open()
	_press(screen.delete_button(a))
	_press(screen.get_node("%ConfirmYes"))
	assert_false(Session.store.has_world(a))
	assert_true(Session.store.has_world(b), "other world must stay")
	assert_false(screen.get_node("%Confirm").visible)
	assert_eq(Array(screen.listed_ids()), [b])
	assert_null(screen.world_button(a))
	assert_eq(Screens.last_request, "")


# --- 뒤로 → 캐릭터 선택 ---

func test_back_goes_to_character_select() -> void:
	_press(_open().get_node("%Back"))
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)


# --- 월드를 고르면 캐릭터와 월드를 들고 게임으로 ---

func test_pick_world_enters_game_with_character_and_world() -> void:
	_character(1, "나루")
	_world("A")
	var b := _world("B")
	_press(_open().world_button(b))
	assert_eq(Screens.last_request, Screens.GAME)
	assert_true(Session.ready_to_play())
	assert_eq(Session.character_slot, 1)
	assert_eq(Session.character.name, "나루")
	assert_eq(Session.world_id, b)
	assert_eq(Session.world.name, "B")


func test_pick_world_without_character_goes_back_to_select() -> void:
	var a := _world("A")
	_press(_open().world_button(a))
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)
	assert_false(Session.ready_to_play())


func test_game_scene_loads() -> void:
	assert_not_null(load(Screens.GAME) as PackedScene, "cannot load " + Screens.GAME)


func test_world_screen_text_in_each_language() -> void:
	var screen := _open()
	var create: Button = screen.get_node("%Create")
	var saved := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	assert_eq(create.atr(create.text), "만들기")
	TranslationServer.set_locale("en")
	assert_eq(create.atr(create.text), "Create")
	TranslationServer.set_locale(saved)
	for edit in [screen.get_node("%NameEdit"), screen.get_node("%SeedEdit")]:
		var key: String = edit.placeholder_text
		assert_eq(key, key.to_upper(), "placeholder must be a translation key")
		assert_ne(TranslationServer.get_translation_object("ko").get_message(key), "")
		assert_ne(TranslationServer.get_translation_object("en").get_message(key), "")
