class_name Player
extends CharacterBody2D

## 색 네모 플레이어. 그림은 프로토타입 범위 밖이라 ColorRect 한 장이다 (BACKLOG 머리말).
##
## 계산은 전부 PlayerMotion · PlayerFacing 에 있다 — 이 파일은 **입력을 읽어서 넘기고
## 움직이고 그리는 것**만 한다.
## 충돌은 아직 없다 (P1-5). move_and_slide 를 지금부터 쓰는 것은 그때 그대로 얹히기 때문이다.
##
## **이동과 방향은 별개다** (GDD D-2c): 몸은 WASD 로 가고 얼굴은 커서를 본다.

## 코 네모의 중심이 몸 중심에서 몇 px 떨어지나. 몸통 반폭 24 보다 커야 밖으로 나온다.
const NOSE_DIST := 28.0

## 바라보는 방향. AXES 중 하나다 — 대각선은 없다.
var facing: Vector2 = Vector2.RIGHT

@onready var _nose: ColorRect = $Nose

func _ready() -> void:
	_place_nose()

func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = PlayerMotion.velocity(input)
	move_and_slide()
	aim_at(get_global_mouse_position())

## 세계 좌표의 한 점을 겨눈다. 실측 게이트가 커서 없이 부를 수 있게 밖으로 냈다.
func aim_at(point: Vector2) -> void:
	facing = PlayerFacing.resolve(point - global_position, facing)
	_place_nose()

func _place_nose() -> void:
	_nose.position = facing * NOSE_DIST - _nose.size * 0.5
