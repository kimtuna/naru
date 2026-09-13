extends SceneTree

## 헤드리스 테스트 러너. tools/tests/test_*.gd 를 전부 찾아
## test_ 로 시작하는 메서드를 하나씩 돌린다.
##
## 종료 코드로 판정한다 — 사람이 출력을 읽고 판단하지 않는다.

const TEST_DIR := "res://tools/tests"

func _initialize() -> void:
	var files := _find_tests()
	if files.is_empty():
		print("TESTS 0 passed, 0 failed  (검사 파일을 못 찾았다 — 이건 실패다)")
		quit(1)
		return

	var passed := 0
	var failed := 0
	for path in files:
		var scr: Script = load(path)
		if scr == null:
			failed += 1
			print("  FAIL %s :: (로드 실패)" % path.get_file())
			continue
		for method_name in _test_methods(scr):
			var inst: TestBase = scr.new()
			inst.call(method_name)
			if inst.failures.is_empty():
				passed += 1
				print("  ok   %s :: %s" % [path.get_file(), method_name])
			else:
				failed += 1
				for f in inst.failures:
					print("  FAIL %s :: %s — %s" % [path.get_file(), method_name, f])

	print("TESTS %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _find_tests() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(TEST_DIR)
	if d == null:
		push_error("테스트 디렉터리를 못 연다: %s" % TEST_DIR)
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if not d.current_is_dir() and f.begins_with("test_") and f.ends_with(".gd"):
			out.append("%s/%s" % [TEST_DIR, f])
		f = d.get_next()
	d.list_dir_end()
	out.sort()
	return out

func _test_methods(scr: Script) -> Array[String]:
	var names: Array[String] = []
	var probe: Object = scr.new()
	for m in probe.get_method_list():
		var n: String = m.name
		if n.begins_with("test_") and not names.has(n):
			names.append(n)
	names.sort()
	return names
