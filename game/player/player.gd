class_name Player
extends CharacterBody2D
## 플레이어 캐릭터 — WASD 8방향 이동. 카메라(자식 Camera2D)가 따라간다.
## 대각선은 정규화해 어느 방향이든 속력이 같다 (spec/02_player/movement-controls.md).

## 비워 두면 movement_tuning.tres 를 쓴다.
@export var tuning: MovementTuning


func _ready() -> void:
	if tuning == null:
		tuning = MovementTuning.load_default()


func _physics_process(_delta: float) -> void:
	velocity = InputActions.move_vector() * tuning.move_speed
	move_and_slide()


func camera() -> Camera2D:
	return %Camera
