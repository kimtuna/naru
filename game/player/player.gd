class_name Player
extends CharacterBody2D
## 플레이어 캐릭터 — WASD 8방향 이동. 카메라(자식 Camera2D)가 따라간다.
## 대각선은 정규화해 어느 방향이든 속력이 같다 (spec/02_player/movement-controls.md).
## 바라보는 방향은 Pointer(마우스) 쪽이고 이동 방향과 상관없다 — 뒷걸음질 · 게걸음이 된다.

## 비워 두면 movement_tuning.tres 를 쓴다.
@export var tuning: MovementTuning

## 바라보는 방향 (길이 1). 커서가 캐릭터 한가운데에 있으면 앞서 보던 방향을 그대로 둔다.
var facing := Vector2.RIGHT


func _ready() -> void:
	if tuning == null:
		tuning = MovementTuning.load_default()


func _physics_process(_delta: float) -> void:
	update_facing()
	velocity = InputActions.move_vector() * tuning.move_speed
	move_and_slide()


## 커서 쪽으로 바라보는 방향을 맞추고 조준 표시를 돌린다. 이번 걸음에서 움직이기 전 위치 기준이다.
func update_facing() -> void:
	var to_pointer := Pointer.global_position(self) - global_position
	if not to_pointer.is_zero_approx():
		facing = to_pointer.normalized()
	%Aim.rotation = facing.angle()


func camera() -> Camera2D:
	return %Camera
