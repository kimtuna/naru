class_name Player
extends CharacterBody2D
## 플레이어 캐릭터 — WASD 8방향 이동. 카메라(자식 Camera2D)가 따라간다.
## 대각선은 정규화해 어느 방향이든 속력이 같다 (spec/02_player/movement-controls.md).
## 바라보는 방향은 Pointer(마우스) 쪽이고 이동 방향과 상관없다 — 뒷걸음질 · 게걸음이 된다.

## 비워 두면 movement_tuning.tres 를 쓴다.
@export var tuning: MovementTuning

## 핫바 — 숫자키로 칸을 고르고, 고른 칸의 아이템이 손에 든 것이다.
## 게임 씬이 캐릭터의 핫바로 바꿔 끼운다. 혼자 띄우면 새 캐릭터(빈손)의 핫바.
var hotbar := Hotbar.new()
## 바라보는 방향 (길이 1). 커서가 캐릭터 한가운데에 있으면 앞서 보던 방향을 그대로 둔다.
var facing := Vector2.RIGHT
## 참을 돌려주는 동안(설정 창이 열려 있는 동안) 이동 입력을 받지 않는다. 게임 씬이 채운다.
var blocked := Callable()
## 걸린 버프 — 버프 음식을 먹으면 걸리고 시간이 지나면 풀린다. 이동 속력에 곱해진다.
var buffs := Buffs.new()


func _ready() -> void:
	if tuning == null:
		tuning = MovementTuning.load_default()
	DisplayConfig.lock_camera(%Camera)


func _physics_process(delta: float) -> void:
	buffs.tick(delta)
	update_facing()
	velocity = Vector2.ZERO if is_blocked() else InputActions.move_vector() * move_speed()
	move_and_slide()


## 지금 이동 속력 — 기본 속력에 버프 배수를 곱한다.
func move_speed() -> float:
	return tuning.move_speed * buffs.move_speed_multiplier()


func is_blocked() -> bool:
	return blocked.is_valid() and blocked.call()


## 커서 쪽으로 바라보는 방향을 맞추고 조준 표시를 돌린다. 이번 걸음에서 움직이기 전 위치 기준이다.
func update_facing() -> void:
	var to_pointer := Pointer.global_position(self) - global_position
	if not to_pointer.is_zero_approx():
		facing = to_pointer.normalized()
	%Aim.rotation = facing.angle()


func _unhandled_input(event: InputEvent) -> void:
	var slot := InputActions.hotbar_slot_pressed(event)
	if slot > 0 and hotbar.select(slot):
		get_viewport().set_input_as_handled()


## 손에 든 것 — 핫바에서 고른 칸의 아이템. 빈손이면 null.
func held_item() -> Variant:
	return hotbar.held_item()


## 휘두른 표시 (바라보는 방향 앞) — Swinger 가 켜고 끈다.
func show_swing(on: bool) -> void:
	%Swing.visible = on


func is_swing_shown() -> bool:
	return %Swing.visible


func camera() -> Camera2D:
	return %Camera
