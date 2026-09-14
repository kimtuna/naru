class_name Player
extends CharacterBody2D

## 색 네모 플레이어. 그림은 프로토타입 범위 밖이라 ColorRect 한 장이다 (BACKLOG 머리말).
##
## 계산은 전부 PlayerMotion · PlayerFacing · WorldCollide 에 있다 — 이 파일은
## **입력을 읽어서 넘기고 움직이고 그리는 것**만 한다.
##
## **`move_and_slide` 를 안 쓴다** (P1-5): 바다는 정적 몸이 아니라 타일 격자다.
## 65536칸에 몸을 세울 수 없고, 창 주변만 세우면 결과가 「지금 무엇이 세워져 있나」에
## 달린다 — 재현 가능한 이동이 필요하다 (WorldCollide 머리말).
##
## **이동과 방향은 별개다** (GDD D-2c): 몸은 WASD 로 가고 얼굴은 커서를 본다.

## 코 네모의 중심이 몸 중심에서 몇 px 떨어지나. 몸통 반폭 24 보다 커야 밖으로 나온다.
const NOSE_DIST := 28.0

## 바라보는 방향. AXES 중 하나다 — 대각선은 없다.
var facing: Vector2 = Vector2.RIGHT

## 「이 칸이 막나」를 묻는 자리. 월드를 아는 쪽(main.gd)이 꽂아 준다.
## **비어 있으면 아무것도 안 막는다** — 플레이어 씬만 띄우는 검사가 월드 없이 돌아야 한다.
var solid := Callable()

@onready var _nose: ColorRect = $Nose

func _ready() -> void:
	_place_nose()

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = PlayerMotion.velocity(input)
	position = WorldCollide.move(position, velocity * delta, solid)
	aim_at(get_global_mouse_position())

## 세계 좌표의 한 점을 겨눈다. 실측 게이트가 커서 없이 부를 수 있게 밖으로 냈다.
func aim_at(point: Vector2) -> void:
	facing = PlayerFacing.resolve(point - global_position, facing)
	_place_nose()

func _place_nose() -> void:
	_nose.position = facing * NOSE_DIST - _nose.size * 0.5
