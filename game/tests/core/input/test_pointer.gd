extends GutTest
## G-003 1단계 — Pointer: 흉내 낸 위치가 그대로 나오고, NARU_SHOT=1 이면 실제 커서를 읽지 않는다.

var _saved_env := ""
var _saved_reader: Callable
var _real_calls := 0
var _item: Node2D


func before_each() -> void:
	_saved_env = OS.get_environment(Pointer.SHOT_ENV)
	OS.unset_environment(Pointer.SHOT_ENV)
	_saved_reader = Pointer.real_reader
	_real_calls = 0
	Pointer.real_reader = _spy_reader
	Pointer.clear_simulation()
	_item = add_child_autofree(Node2D.new())


func after_each() -> void:
	Pointer.real_reader = _saved_reader
	Pointer.clear_simulation()
	if _saved_env == "":
		OS.unset_environment(Pointer.SHOT_ENV)
	else:
		OS.set_environment(Pointer.SHOT_ENV, _saved_env)


func _spy_reader(_it: CanvasItem) -> Vector2:
	_real_calls += 1
	return Vector2(777, -333)


func test_simulated_position_comes_back_unchanged() -> void:
	Pointer.simulate(Vector2(12.5, -40))
	assert_true(Pointer.is_simulated())
	assert_eq(Pointer.global_position(_item), Vector2(12.5, -40))
	Pointer.simulate(Vector2(300, 200))
	assert_eq(Pointer.global_position(_item), Vector2(300, 200))
	assert_eq(_real_calls, 0, "simulation must not touch the real cursor")


func test_without_simulation_reads_real_cursor() -> void:
	assert_eq(Pointer.global_position(_item), Vector2(777, -333))
	assert_eq(_real_calls, 1)


func test_clear_simulation_goes_back_to_real() -> void:
	Pointer.simulate(Vector2(1, 2))
	Pointer.clear_simulation()
	assert_false(Pointer.is_simulated())
	assert_eq(Pointer.global_position(_item), Vector2(777, -333))


func test_shot_mode_never_reads_real_cursor() -> void:
	OS.set_environment(Pointer.SHOT_ENV, "1")
	assert_true(Pointer.is_shot_mode())
	var pos := Pointer.global_position(_item)
	assert_eq(_real_calls, 0, "NARU_SHOT=1 must not read the real cursor")
	assert_ne(pos, Vector2(777, -333))
	var center := _item.get_viewport_rect().size / 2.0
	assert_eq(pos, _item.get_canvas_transform().affine_inverse() * center, "shot mode uses screen center")


func test_shot_mode_still_honors_simulation() -> void:
	OS.set_environment(Pointer.SHOT_ENV, "1")
	Pointer.simulate(Vector2(5, 6))
	assert_eq(Pointer.global_position(_item), Vector2(5, 6))
	assert_eq(_real_calls, 0)


func test_shot_env_other_than_1_is_normal_mode() -> void:
	OS.set_environment(Pointer.SHOT_ENV, "0")
	assert_false(Pointer.is_shot_mode())
	Pointer.global_position(_item)
	assert_eq(_real_calls, 1)


func test_default_reader_is_real_mouse() -> void:
	# 기본 reader 가 실제 커서 읽기인지 — headless 에서 부르면 오류 없이 Vector2 가 나와야 한다.
	var v = _saved_reader.call(_item)
	assert_typeof(v, TYPE_VECTOR2)
