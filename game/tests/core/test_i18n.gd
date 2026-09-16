extends GutTest
## G-001 3단계 — 번역 뼈대 수용 기준.

const LOCALES := ["ko", "en"]
const TITLE_KEY := "MAIN_TITLE"

var _saved_locale := ""


func before_each() -> void:
	_saved_locale = TranslationServer.get_locale()


func after_each() -> void:
	TranslationServer.set_locale(_saved_locale)


func _registered() -> PackedStringArray:
	return ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray())


func test_translation_files_exist_and_are_registered() -> void:
	var registered := _registered()
	for locale in LOCALES:
		var found := ""
		for path in registered:
			if path.begins_with("res://i18n/"):
				var tr_res := load(path) as Translation
				if tr_res and tr_res.locale == locale:
					found = path
		assert_ne(found, "", "no registered translation in res://i18n/ for " + locale)
		if found != "":
			assert_true(FileAccess.file_exists(found), "missing file: " + found)


func test_locales_share_the_same_keys() -> void:
	var keys := {}
	for path in _registered():
		var tr_res := load(path) as Translation
		assert_not_null(tr_res, "cannot load " + path)
		if tr_res:
			var list := Array(tr_res.get_message_list())
			list.sort()
			keys[tr_res.locale] = list
	assert_has(keys.get("ko", []), TITLE_KEY)
	assert_eq(keys.get("ko", []), keys.get("en", []), "ko/en key sets differ")


func test_main_scene_title_changes_with_locale() -> void:
	var scene := load(ProjectSettings.get_setting("application/run/main_scene")) as PackedScene
	var main: Node = add_child_autofree(scene.instantiate())
	var label := main.get_node_or_null("Title") as Label
	assert_not_null(label, "main scene has no Title label")
	if label == null:
		return
	assert_eq(label.text, TITLE_KEY, "label must hold a translation key, not literal text")

	TranslationServer.set_locale("ko")
	await wait_process_frames(1)
	assert_eq(label.atr(label.text), "나루")
	assert_eq(label.get_total_character_count(), "나루".length(), "rendered text not Korean")

	TranslationServer.set_locale("en")
	await wait_process_frames(1)
	assert_eq(label.atr(label.text), "Naru")
	assert_eq(label.get_total_character_count(), "Naru".length(), "rendered text not English")
