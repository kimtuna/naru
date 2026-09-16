extends GutTest
## G-002 2단계 — 메인 화면 수용 기준.

const MENU_SCENES := [Screens.MAIN_MENU, Screens.SETTINGS, Screens.CHARACTER_SELECT,
	Screens.CHARACTER_CREATE, Screens.WORLD_SELECT]
const LOCALES := ["ko", "en"]
const PROBE := "res://tests/ui/menu/menu_flow_probe.gd"


func before_each() -> void:
	Screens.simulate = true
	Screens.last_request = ""
	# 실제 사용자 저장을 읽지 않는다 — 없는 임시 폴더라 슬롯은 모두 빈 칸.
	Session.store = SaveStore.new(OS.get_temp_dir().path_join("naru_menu_empty_%d" % Time.get_ticks_usec()))


func after_each() -> void:
	Screens.simulate = false
	Session.store = SaveStore.new()


func _open(path: String) -> Control:
	return add_child_autofree((load(path) as PackedScene).instantiate())


func _press(screen: Node, button_name: String) -> void:
	var button := screen.find_child(button_name, true, false) as Button
	assert_not_null(button, "missing button: " + button_name)
	if button:
		assert_true(button.is_visible_in_tree(), button_name + " not visible")
		button.pressed.emit()


# --- 게임을 실행하면 메인 화면이 뜬다 ---

func test_project_main_scene_is_main_menu() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), Screens.MAIN_MENU)


func test_main_menu_has_start_settings_quit_in_order() -> void:
	var menu := _open(Screens.MAIN_MENU)
	var items: Array = menu.get_node("Items").get_children().map(func(n): return String(n.name))
	assert_eq(items, ["Start", "Settings", "Quit"])


# --- 버튼 → 화면 전환 요청 ---

func test_start_goes_to_character_select() -> void:
	_press(_open(Screens.MAIN_MENU), "Start")
	assert_eq(Screens.last_request, Screens.CHARACTER_SELECT)


func test_settings_goes_to_settings() -> void:
	_press(_open(Screens.MAIN_MENU), "Settings")
	assert_eq(Screens.last_request, Screens.SETTINGS)


func test_settings_back_goes_to_main_menu() -> void:
	_press(_open(Screens.SETTINGS), "Back")
	assert_eq(Screens.last_request, Screens.MAIN_MENU)


func test_quit_requests_quit() -> void:
	_press(_open(Screens.MAIN_MENU), "Quit")
	assert_eq(Screens.last_request, Screens.QUIT)


func test_target_screens_load() -> void:
	for path in MENU_SCENES:
		var scene := load(path) as PackedScene
		assert_not_null(scene, "cannot load " + path)


# --- 실제 실행: 씬이 정말 바뀌고, 종료 버튼으로 프로세스가 끝난다 ---

func test_real_flow_in_separate_process() -> void:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "-s", PROBE], output, true)
	var text := "\n".join(output)
	var steps := []
	for line in text.split("\n"):
		if line.begins_with("STEP "):
			steps.append(line.substr(5).strip_edges())
	assert_eq(steps, [
		Screens.MAIN_MENU, Screens.CHARACTER_SELECT, Screens.MAIN_MENU,
		Screens.SETTINGS, Screens.MAIN_MENU,
	], "flow:\n" + text)
	assert_eq(code, 0, "quit button must end the game cleanly:\n" + text)
	assert_false(text.contains("ERROR"), "errors in output:\n" + text)


# --- 모든 글자가 번역 키, 한국어 · 영어 둘 다 ---

func _texts(node: Node, out: Array) -> Array:
	if node is Label or node is Button:
		out.append(node.text)
	for child in node.get_children():
		_texts(child, out)
	return out


func test_all_screen_text_is_translated_in_ko_and_en() -> void:
	var catalogs := {}
	for path in ProjectSettings.get_setting("internationalization/locale/translations"):
		var t := load(path) as Translation
		catalogs[t.locale] = t
	for locale in LOCALES:
		assert_has(catalogs, locale, "no translation for " + locale)
	for path in MENU_SCENES:
		var texts := _texts(_open(path), [])
		assert_gt(texts.size(), 0, path + " has no text")
		for key in texts:
			assert_eq(key, key.to_upper(), "%s: '%s' is not a translation key" % [path, key])
			for locale in LOCALES:
				if catalogs.has(locale):
					var msg: String = catalogs[locale].get_message(key)
					assert_true(msg != "" and msg != key, "%s: %s missing in %s" % [path, key, locale])


func test_buttons_render_in_each_language() -> void:
	var menu := _open(Screens.MAIN_MENU)
	var start := menu.find_child("Start", true, false) as Button
	var saved := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	await wait_process_frames(1)
	assert_eq(start.atr(start.text), "시작")
	TranslationServer.set_locale("en")
	await wait_process_frames(1)
	assert_eq(start.atr(start.text), "Start")
	TranslationServer.set_locale(saved)
