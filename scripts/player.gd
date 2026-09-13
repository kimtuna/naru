class_name Player
extends CharacterBody2D

## 색 네모 플레이어. 그림은 프로토타입 범위 밖이라 ColorRect 한 장이다 (BACKLOG 머리말).
##
## 계산은 전부 PlayerMotion 에 있다 — 이 파일은 **입력을 읽어서 넘기고 움직이는 것**만 한다.
## 충돌은 아직 없다 (P1-5). move_and_slide 를 지금부터 쓰는 것은 그때 그대로 얹히기 때문이다.

func _physics_process(_delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = PlayerMotion.velocity(input)
	move_and_slide()
