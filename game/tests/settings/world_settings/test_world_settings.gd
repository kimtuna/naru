extends "res://tests/ui/menu/game_menu_test_base.gd"
## G-009 2단계 — 월드 설정: 데스 페널티 (기본 켬 · 월드 저장), 게임 중 설정 창에서 바로 바꿈, 서버장이 아니면 거부.


func _toggle(menu: GameMenu) -> CheckButton:
	return menu.button("DeathPenalty") as CheckButton


# --- 항목 · 기본값 · 저장 ---

func test_death_penalty_defaults_on() -> void:
	assert_true(WorldSettings.new().death_penalty)
	assert_true(WorldData.create("섬", 1).settings.death_penalty, "new world starts with penalty on")
	assert_true(WorldData.from_dict({"name": "옛 섬", "seed": 3}).settings.death_penalty,
		"old saves without settings fall back to on")
	assert_true(WorldData.from_dict({"settings": {"death_penalty": "no"}}).settings.death_penalty,
		"broken value falls back to on")


func test_death_penalty_is_kept_in_world_save() -> void:
	var w := WorldData.create("섬", 7)
	assert_true(w.settings.set_death_penalty(false, true))
	var id := Session.store.create_world(w)
	assert_ne(id, "")
	var loaded := Session.store.load_world(id)
	assert_false(loaded.settings.death_penalty, "off survives save/load")
	assert_true(loaded.settings.set_death_penalty(true, true))
	Session.store.save_world(id, loaded)
	assert_true(Session.store.load_world(id).settings.death_penalty, "on survives save/load")
	Session.store.delete_world(id)


# --- 서버장이 아니면 거부 ---

func test_non_host_change_is_rejected() -> void:
	var s := WorldSettings.new()
	watch_signals(s)
	assert_false(s.set_death_penalty(false, false), "non-host change is refused")
	assert_true(s.death_penalty, "value unchanged after refusal")
	assert_signal_not_emitted(s, "changed")
	assert_true(s.set_death_penalty(false, true), "host change is accepted")
	assert_false(s.death_penalty)
	assert_signal_emitted_with_parameters(s, "changed", [WorldSettings.DEATH_PENALTY, false])


func test_non_host_toggle_in_menu_is_rejected() -> void:
	Session.select_character(0)
	Session.select_world(_world_id)
	Session.is_host = false
	var game: GameScene = (load(Screens.GAME) as PackedScene).instantiate()
	add_child(game)
	_games.append(game)
	var menu := _menu(game)
	# 페이지는 안 보이지만, 어떻게든 눌렸다고 흉내 낸다.
	_toggle(menu).button_pressed = false
	assert_true(game.world.settings.death_penalty, "non-host toggle must not change the world")
	assert_true(game.death_penalty_on())
	assert_true(_toggle(menu).button_pressed, "toggle snaps back to the real value")


# --- 게임 중 설정 창에서 바로 바뀐다 ---

func test_host_changes_death_penalty_in_game_menu() -> void:
	var game := _enter()
	assert_true(game.death_penalty_on(), "default on in game")
	await _esc()
	var menu := _menu(game)
	_press(menu.button("WorldSettings"))
	assert_eq(menu.page(), GameMenu.PAGE_WORLD_SETTINGS)
	var toggle := _toggle(menu)
	assert_true(toggle.is_visible_in_tree(), "death penalty item is on the world settings page")
	assert_true(toggle.button_pressed, "item shows the current value")
	assert_false(toggle.disabled)
	toggle.button_pressed = false
	assert_false(game.world.settings.death_penalty, "applied to the world right away")
	assert_false(game.death_penalty_on(), "game sees the new value right away")
	assert_true(menu.is_open(), "menu stays open")
	toggle.button_pressed = true
	assert_true(game.death_penalty_on())
	toggle.button_pressed = false
	# 나가면서 저장 — 월드 저장에 남는다.
	_press(menu.button("WorldSettingsBack"))
	_press(menu.button("MainMenu"))
	assert_false(Session.store.load_world(_world_id).settings.death_penalty, "change saved with the world")


func test_world_settings_page_reflects_loaded_value() -> void:
	var w := Session.store.load_world(_world_id)
	w.settings.set_death_penalty(false, true)
	Session.store.save_world(_world_id, w)
	var game := _enter()
	await _esc()
	var menu := _menu(game)
	_press(menu.button("WorldSettings"))
	assert_false(_toggle(menu).button_pressed, "page shows the saved off value")
	assert_false(game.death_penalty_on())


func test_death_penalty_label_is_translated() -> void:
	var saved := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	assert_eq(tr("WORLD_SETTINGS_DEATH_PENALTY"), "데스 페널티")
	TranslationServer.set_locale("en")
	assert_eq(tr("WORLD_SETTINGS_DEATH_PENALTY"), "Death penalty")
	TranslationServer.set_locale(saved)
