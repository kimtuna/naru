extends GutTest
## G-002 5단계 — 게임 씬(빈 자리) 들어가기 · 나가기 · 캐릭터를 월드 사이에 데려가기.

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_game_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	Screens.last_request = ""


func after_each() -> void:
	Screens.simulate = false
	Session.store = SaveStore.new()
	Session.clear()
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


func _setup(char_name: String, world_names: Array) -> Array:
	var c := CharacterData.new()
	c.name = char_name
	assert_eq(Session.store.save_character(0, c), OK)
	var ids := []
	for n in world_names:
		ids.append(Session.store.create_world(WorldData.create(n, 7)))
	return ids


## 메뉴가 하는 그대로 캐릭터 → 월드를 고르고, 월드 선택 화면에서 월드를 눌러 게임 씬을 연다.
func _enter(slot: int, world_id: String) -> Node:
	Session.select_character(slot)
	var select: Control = add_child_autofree((load(Screens.WORLD_SELECT) as PackedScene).instantiate())
	select.world_button(world_id).pressed.emit()
	assert_eq(Screens.last_request, Screens.GAME)
	Screens.last_request = ""
	# 실제로는 화면 전환으로 사라진다 — 남겨 두면 그 화면이 Esc(뒤로)를 먼저 받는다.
	remove_child(select)
	select.queue_free()
	return add_child_autofree((load(Screens.GAME) as PackedScene).instantiate())


## Esc 로 설정 창을 열고 「메인 화면으로」를 누른다 (G-012 부터 Esc 는 바로 나가지 않는다).
func _press_exit(game: Node) -> void:
	await _press_escape()
	assert_true(game.game_menu().is_open(), "Esc opens the game menu")
	game.game_menu().button("MainMenu").pressed.emit()


func _press_escape() -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_ESCAPE
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_process_frames(2)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	Input.flush_buffered_events()
	await wait_process_frames(1)


# --- 게임 씬은 캐릭터 이름과 월드 이름을 안다 ---

func test_game_knows_character_and_world_names() -> void:
	var ids := _setup("나루", ["섬 X"])
	var game := _enter(0, ids[0])
	assert_eq(game.character_name(), "나루")
	assert_eq(game.world_name(), "섬 X")
	assert_eq(game.get_node("%CharacterName").text, "나루")
	assert_eq(game.get_node("%WorldName").text, "섬 X")
	assert_eq(game.get_node("%CharacterName").auto_translate_mode, Node.AUTO_TRANSLATE_MODE_DISABLED)


# --- 나가기: InputMap 액션 → 설정 창 → 저장하고 메인 화면 ---

func test_exit_action_is_in_input_map() -> void:
	assert_true(InputMap.has_action(GameScene.EXIT_ACTION), "missing InputMap action")
	var keys := InputMap.action_get_events(GameScene.EXIT_ACTION).filter(func(e): return e is InputEventKey)
	assert_gt(keys.size(), 0, "exit action has no key")


func test_exit_key_saves_and_goes_to_main_menu() -> void:
	var ids := _setup("A", ["X"])
	var game := _enter(0, ids[0])
	game.character.appearance["body"] = "changed"
	game.world.world_seed = 999
	await _press_exit(game)
	assert_eq(Screens.last_request, Screens.MAIN_MENU)
	assert_eq(Session.store.load_character(0).appearance.get("body"), "changed", "character not saved")
	assert_eq(Session.store.load_world(ids[0]).world_seed, 999, "world not saved")
	assert_false(Session.ready_to_play(), "session must be cleared after leaving")


func test_other_keys_do_not_exit() -> void:
	var ids := _setup("A", ["X"])
	_enter(0, ids[0])
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_W
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await wait_process_frames(2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	assert_eq(Screens.last_request, "")


# --- 같은 캐릭터로 월드 X 에서 넣은 인벤토리가 월드 Y 에서도 그대로 ---

func test_inventory_follows_character_across_worlds() -> void:
	var ids := _setup("A", ["X", "Y"])
	var items := [{"id": "stone", "count": 3}, {"id": "wood", "count": 1}]
	var in_x := _enter(0, ids[0])
	assert_eq(in_x.world_name(), "X")
	in_x.character.inventory.append_array(items.duplicate(true))
	await _press_exit(in_x)
	assert_eq(Screens.last_request, Screens.MAIN_MENU)
	in_x.queue_free()
	await wait_process_frames(1)

	var in_y := _enter(0, ids[1])
	assert_eq(in_y.world_name(), "Y")
	assert_eq(in_y.character_name(), "A")
	assert_eq(in_y.character.inventory, items)
	# 월드에는 인벤토리가 붙지 않는다 — 월드 파일은 그대로.
	assert_false(Session.store.load_world(ids[1]).to_dict().has("inventory"))
