extends GutTest
## G-001 1단계 — 프로젝트 기반 수용 기준.

const SPEC_FOLDERS := [
	"core", "settings", "player", "world", "life", "craft", "build", "automation",
	"combat", "expedition", "economy", "multiplayer", "ui", "tests", "i18n",
]


func test_spec_folders_exist() -> void:
	for folder in SPEC_FOLDERS:
		assert_true(DirAccess.dir_exists_absolute("res://" + folder), "missing folder: " + folder)


func test_main_scene_is_set_and_loads() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	assert_ne(path, "", "main scene not set")
	var scene := load(path) as PackedScene
	assert_not_null(scene, "main scene failed to load: " + path)
	if scene:
		var node := scene.instantiate()
		assert_not_null(node)
		node.free()


func test_headless_quit_exits_clean() -> void:
	var output: Array = []
	var project_dir := ProjectSettings.globalize_path("res://")
	var code := OS.execute(OS.get_executable_path(),
		["--headless", "--path", project_dir, "--quit"], output, true)
	assert_eq(code, 0, "exit code")
	var text := "\n".join(output)
	assert_false(text.contains("ERROR"), "errors in output:\n" + text)
	assert_false(text.contains("SCRIPT ERROR"), "script errors in output:\n" + text)


func test_gitignore_excludes_godot_cache() -> void:
	var gitignore := ProjectSettings.globalize_path("res://").path_join("../.gitignore")
	var file := FileAccess.open(gitignore, FileAccess.READ)
	assert_not_null(file, ".gitignore not found")
	if file:
		var lines := file.get_as_text().split("\n")
		assert_has(Array(lines).map(func(l): return l.strip_edges()), "game/.godot/")
