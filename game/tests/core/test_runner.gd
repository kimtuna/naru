extends GutTest
## G-001 2단계 — tools/test.sh 가 결과에 맞는 종료 코드를 내는지 확인한다.
## user:// 에 임시 테스트를 만들고 TEST_DIR 로 실행기를 그 폴더에 돌린다.

const WORK_DIR := "user://runner_selftest"

const PASSING := "extends GutTest\nfunc test_ok() -> void:\n\tassert_true(true)\n"
const FAILING := "extends GutTest\nfunc test_bad() -> void:\n\tassert_eq(1, 2)\n"
const BROKEN := "extends GutTest\nfunc test_broken() -> void:\n\tassert_eq(1,\n"


func before_each() -> void:
	_clear_work_dir()
	DirAccess.make_dir_recursive_absolute(WORK_DIR)


func after_all() -> void:
	_clear_work_dir()


func test_all_passing_exits_zero() -> void:
	_write("test_pass.gd", PASSING)
	_expect_exit(true)


func test_one_failing_exits_nonzero() -> void:
	_write("test_pass.gd", PASSING)
	_write("test_fail.gd", FAILING)
	_expect_exit(false)


func test_failing_in_subfolder_exits_nonzero() -> void:
	_write("test_pass.gd", PASSING)
	DirAccess.make_dir_recursive_absolute(WORK_DIR + "/sub")
	_write("sub/test_fail.gd", FAILING)
	_expect_exit(false)


func test_script_error_exits_nonzero() -> void:
	_write("test_pass.gd", PASSING)
	_write("test_broken.gd", BROKEN)
	_expect_exit(false)


func test_no_tests_exits_nonzero() -> void:
	_expect_exit(false)


func _expect_exit(zero: bool) -> void:
	var output: Array = []
	var code := _run_runner(output)
	var ok := (code == 0) == zero
	assert_true(ok, "exit=%d, expected %s\n%s" % [code, "0" if zero else "non-zero", "\n".join(output)])


func _run_runner(output: Array) -> int:
	var root := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var script := root.path_join("tools/test.sh")
	var cmd := "TEST_DIR='%s' GODOT='%s' '%s'" % [WORK_DIR, OS.get_executable_path(), script]
	return OS.execute("bash", ["-c", cmd], output, true)


func _write(rel_path: String, text: String) -> void:
	var file := FileAccess.open(WORK_DIR.path_join(rel_path), FileAccess.WRITE)
	assert_not_null(file, "cannot write " + rel_path)
	if file:
		file.store_string(text)


func _clear_work_dir() -> void:
	_remove_recursive(WORK_DIR)


func _remove_recursive(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for sub in DirAccess.get_directories_at(path):
		_remove_recursive(path.path_join(sub))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)
