extends "res://tests/settings/display/fit_test_base.gd"
## G-010 2단계 — 글자 크기는 640×360 에서 읽을 수 있는 값으로 한 곳(테마)에 정해져 있다.

## 글자 크기 오버라이드를 찾을 곳 (테스트 · 애드온 제외).
const SOURCE_DIRS := ["res://ui", "res://world", "res://player", "res://craft", "res://life", "res://core", "res://settings"]


func _theme() -> Theme:
	return load(UiTheme.PATH) as Theme


func test_font_sizes_are_readable_and_live_in_the_theme() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), UiTheme.PATH, "project does not use the game theme")
	var theme := _theme()
	assert_not_null(theme)
	if theme == null:
		return
	assert_true(theme.has_default_font_size(), "theme has no default font size")
	var sizes := [theme.default_font_size]
	for type in theme.get_font_size_type_list():
		for n in theme.get_font_size_list(type):
			sizes.append(theme.get_font_size(n, type))
	for s in sizes:
		assert_between(s, UiTheme.MIN_FONT_SIZE, UiTheme.MAX_FONT_SIZE, "theme font size %d" % s)
	# 한 줄 높이로 기준 화면에 여러 줄이 들어간다.
	assert_gt(SCREEN.size.y / theme.default_font_size, 20.0)


func test_every_shown_text_uses_a_theme_font_size() -> void:
	var theme := _theme()
	var allowed := {theme.default_font_size: true}
	for type in theme.get_font_size_type_list():
		for n in theme.get_font_size_list(type):
			allowed[theme.get_font_size(n, type)] = true
	var screens: Array[Node] = []
	_character(1, "tester")
	for path in [Screens.MAIN_MENU, Screens.SETTINGS, Screens.CHARACTER_SELECT,
			Screens.CHARACTER_CREATE, Screens.WORLD_SELECT]:
		screens.append(_open(path))
	var game := _enter()
	_fill_bag(game)
	game.inventory_view().set_open(true)
	screens.append(game)
	await wait_process_frames(2)
	var texts := 0
	for s in screens:
		for c in s.find_children("*", "Control", true, false):
			if not (c is Label or c is Button or c is LineEdit):
				continue
			texts += 1
			var size: int = c.get_theme_font_size("font_size")
			assert_true(allowed.has(size), "%s font size %d is not from the theme" % [c.get_path(), size])
			assert_gte(size, UiTheme.MIN_FONT_SIZE, "%s font too small" % c.get_path())
			assert_false(c.has_theme_font_size_override("font_size"), "%s overrides font size" % c.get_path())
	assert_gt(texts, 20)


func test_no_font_size_overrides_in_sources() -> void:
	var files := 0
	for dir in SOURCE_DIRS:
		for path in _files(dir):
			if path == UiTheme.PATH:
				continue
			files += 1
			var body := FileAccess.get_file_as_string(path)
			for bad in ["theme_override_font_sizes", "add_theme_font_size_override", "font_size ="]:
				assert_false(body.contains(bad), "%s sets a font size outside the theme (%s)" % [path, bad])
	assert_gt(files, 10)


func _files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_files(dir.path_join(sub)))
	for f in DirAccess.get_files_at(dir):
		if f.get_extension() in ["gd", "tscn", "tres"]:
			out.append(dir.path_join(f))
	return out
