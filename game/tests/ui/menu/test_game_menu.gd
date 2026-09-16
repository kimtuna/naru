extends "res://tests/ui/menu/game_menu_test_base.gd"
## G-012 1단계 — 게임 중 Esc 는 설정 창이다. 열린 창이 있으면 그 창부터 닫는다.
## 설정 창에서 「메인 화면으로」 · 「게임 종료」는 저장한 뒤 나간다. 입력 막기는 test_game_menu_input.gd.


# --- 열린 창이 없으면 Esc → 설정 창, 다시 Esc 또는 「계속하기」 → 닫힘 ---

func test_escape_opens_and_closes_menu() -> void:
	var game := _enter()
	await wait_process_frames(1)
	var menu := _menu(game)
	assert_false(menu.is_visible_in_tree(), "menu starts closed")
	await _esc()
	assert_true(menu.is_open())
	assert_true(menu.is_visible_in_tree(), "Esc shows the menu")
	assert_eq(Screens.last_request, "", "Esc must not leave the game")
	await _esc()
	assert_false(menu.is_visible_in_tree(), "second Esc closes the menu")
	assert_eq(Screens.last_request, "")


func test_continue_closes_menu() -> void:
	var game := _enter()
	await _esc()
	assert_true(_menu(game).is_open())
	_press(_menu(game).button("Continue"))
	assert_false(_menu(game).is_visible_in_tree(), "Continue closes the menu")
	await _esc()
	assert_true(_menu(game).is_open(), "menu opens again after Continue")


# --- 가방 · 제작 화면이 열려 있으면 Esc 는 그 창만 닫는다 ---

func test_escape_closes_bag_first() -> void:
	var game := _enter()
	await _tap_key(KEY_TAB)
	assert_true(game.inventory_view().is_open(), "setup: bag open")
	await _esc()
	assert_false(game.inventory_view().is_open(), "Esc closes the bag")
	assert_false(_menu(game).is_open(), "menu must not open while closing the bag")
	await _esc()
	assert_true(_menu(game).is_open(), "with nothing open, Esc opens the menu")


func test_escape_closes_crafting_first() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	await _right_click_cell(game, cell)
	assert_true(game.crafting_view().is_open(), "setup: crafting open")
	await _esc()
	assert_false(game.crafting_view().is_open(), "Esc closes the crafting screen")
	assert_false(_menu(game).is_open(), "menu must not open while closing crafting")
	await _esc()
	assert_true(_menu(game).is_open())
	await _leave_physics_frame()


func test_escape_closes_crafting_and_bag_one_at_a_time() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	await _right_click_cell(game, cell)
	game.inventory_view().set_open(true)
	await _esc()
	assert_false(game.crafting_view().is_open())
	assert_true(game.inventory_view().is_open(), "one Esc closes one window")
	assert_false(_menu(game).is_open())
	await _esc()
	assert_false(game.inventory_view().is_open())
	assert_false(_menu(game).is_open())
	await _leave_physics_frame()


# --- 항목 ---

func test_menu_items_are_shown_in_order() -> void:
	var game := _enter()
	await _esc()
	var menu := _menu(game)
	var y := -INF
	for item in MENU_ITEMS:
		var b := menu.button(item)
		assert_not_null(b, "missing item " + item)
		assert_true(b.is_visible_in_tree(), item + " hidden")
		assert_gt(b.get_global_rect().position.y, y, item + " out of order")
		y = b.get_global_rect().position.y


func test_settings_is_an_empty_page_with_back() -> void:
	var game := _enter()
	await _esc()
	var menu := _menu(game)
	_press(menu.button("Settings"))
	assert_eq(menu.page(), GameMenu.PAGE_SETTINGS)
	assert_false(menu.button("Continue").is_visible_in_tree(), "list hides on the settings page")
	_press(menu.button("SettingsBack"))
	assert_eq(menu.page(), GameMenu.PAGE_MAIN)
	assert_true(menu.button("Continue").is_visible_in_tree())
	# 안쪽 화면에서 Esc 는 목록으로 돌아가고, 목록에서 한 번 더 누르면 닫힌다.
	_press(menu.button("Settings"))
	await _esc()
	assert_true(menu.is_open())
	assert_eq(menu.page(), GameMenu.PAGE_MAIN)
	await _esc()
	assert_false(menu.is_open())
	assert_eq(Screens.last_request, "")


func test_world_settings_is_an_empty_page_with_back_for_host() -> void:
	var game := _enter()
	await _esc()
	var menu := _menu(game)
	assert_true(menu.button("WorldSettings").is_visible_in_tree(), "host sees world settings")
	_press(menu.button("WorldSettings"))
	assert_eq(menu.page(), GameMenu.PAGE_WORLD_SETTINGS)
	_press(menu.button("WorldSettingsBack"))
	assert_eq(menu.page(), GameMenu.PAGE_MAIN)


func test_world_settings_hidden_for_non_host() -> void:
	Session.select_character(0)
	Session.select_world(_world_id)
	Session.is_host = false
	var game: GameScene = (load(Screens.GAME) as PackedScene).instantiate()
	add_child(game)
	_games.append(game)
	await _esc()
	var menu := _menu(game)
	assert_true(menu.is_open())
	assert_false(menu.button("WorldSettings").is_visible_in_tree(), "only the host sees world settings")
	menu.show_page(GameMenu.PAGE_WORLD_SETTINGS)
	assert_eq(menu.page(), GameMenu.PAGE_MAIN, "non-host cannot open the world settings page")
	for item in MENU_ITEMS:
		if item != "WorldSettings":
			assert_true(menu.button(item).is_visible_in_tree(), item + " hidden for non-host")
	menu.set_host(true)
	assert_true(menu.button("WorldSettings").is_visible_in_tree())


# --- 메인 화면으로 · 게임 종료는 저장한 뒤 나간다 ---

func _change_state(game: GameScene) -> void:
	game.character.appearance["body"] = "changed"
	game.player().hotbar.set_item(2, {"id": "stone", "count": 5})
	game.island.time = 777.0


func _assert_saved() -> void:
	var c := Session.store.load_character(0)
	assert_eq(c.appearance.get("body"), "changed", "character not saved")
	assert_eq(c.inventory[1], {"id": "stone", "count": 5}, "inventory not saved")
	assert_almost_eq(Session.store.load_world(_world_id).world_time, 777.0, 0.5, "world not saved")
	assert_false(Session.ready_to_play(), "session is cleared after leaving")


func test_main_menu_saves_then_leaves() -> void:
	var game := _enter()
	_change_state(game)
	await _esc()
	_press(_menu(game).button("MainMenu"))
	assert_eq(Screens.last_request, Screens.MAIN_MENU)
	_assert_saved()


func test_quit_saves_then_quits() -> void:
	var game := _enter()
	_change_state(game)
	await _esc()
	_press(_menu(game).button("Quit"))
	assert_eq(Screens.last_request, Screens.QUIT)
	_assert_saved()


# --- 모든 글자가 번역 키 ---

func test_all_menu_texts_are_translation_keys() -> void:
	var game := _enter()
	var menu := _menu(game)
	var texts := []
	for node in menu.find_children("*", "", true, false):
		if node is Label or node is Button:
			texts.append(node.text)
	assert_gt(texts.size(), MENU_ITEMS.size())
	var saved := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for key in texts:
			assert_true(key == key.to_upper() and not key.is_empty(), "not a key: " + key)
			assert_ne(TranslationServer.translate(key), StringName(key), "%s has no %s text" % [key, locale])
	TranslationServer.set_locale(saved)
	TranslationServer.set_locale("ko")
	assert_eq(tr("GAME_MENU_CONTINUE"), "계속하기")
	assert_eq(tr("GAME_MENU_MAIN_MENU"), "메인 화면으로")
	assert_eq(tr("GAME_MENU_QUIT"), "게임 종료")
	TranslationServer.set_locale(saved)
