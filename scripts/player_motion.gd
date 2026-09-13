class_name PlayerMotion
extends RefCounted

## 이동의 **순수 계산**. 노드도 엔진 상태도 안 본다 — 그래서 헤드리스로 잴 수 있다.
##
## 값의 출처는 NUMBERS 1절이다: 타일 48px · 속도 240/초(= 5칸/초).
##
## **대각선을 정규화한다.** WASD 네 키를 그대로 더하면 대각선이 339px/s 가 되어
## 「대각선으로만 걷는」 게임이 된다. 입력이 무엇이든 속력은 정확히 SPEED 다.

const TILE := 48.0
const SPEED := 240.0

## 입력(각 축 -1..1)을 초당 속도로 바꾼다.
static func velocity(input: Vector2) -> Vector2:
	if input.is_zero_approx():
		return Vector2.ZERO
	return input.normalized() * SPEED

## delta 초 동안의 변위.
static func step(input: Vector2, delta: float) -> Vector2:
	return velocity(input) * delta

## 타일 좌표의 중심(픽셀).
static func tile_center(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)
