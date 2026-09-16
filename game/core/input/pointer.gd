class_name Pointer
extends RefCounted
## 마우스 위치를 읽는 유일한 곳 — 사람이 이 맥을 같이 쓰므로 게임 코드는 커서를 직접 읽지 않는다.
## - 평소: 실제 커서 위치
## - 테스트: Pointer.simulate(pos) 로 넣은 값
## - NARU_SHOT=1 (화면 캡처): 실제 커서를 읽지 않고 화면 가운데를 쓴다
## 좌표는 모두 캔버스(월드) 전역 좌표다.

const SHOT_ENV := "NARU_SHOT"

static var _simulated := false
static var _simulated_position := Vector2.ZERO
## 실제 커서를 읽는 함수. 테스트가 바꿔 끼워 호출 여부를 본다.
static var real_reader: Callable = _read_real


## 흉내 낸 위치를 쓴다 (clear_simulation 전까지).
static func simulate(pos: Vector2) -> void:
	_simulated = true
	_simulated_position = pos


static func clear_simulation() -> void:
	_simulated = false
	_simulated_position = Vector2.ZERO


static func is_simulated() -> bool:
	return _simulated


static func is_shot_mode() -> bool:
	return OS.get_environment(SHOT_ENV) == "1"


## item 이 있는 캔버스에서의 커서 전역 위치.
static func global_position(item: CanvasItem) -> Vector2:
	if _simulated:
		return _simulated_position
	if is_shot_mode():
		return _screen_center(item)
	return real_reader.call(item)


static func _read_real(item: CanvasItem) -> Vector2:
	return item.get_global_mouse_position()


static func _screen_center(item: CanvasItem) -> Vector2:
	var center := item.get_viewport_rect().size / 2.0
	return item.get_canvas_transform().affine_inverse() * center
