class_name PlayerFacing
extends RefCounted

## 바라보는 방향의 **순수 계산**. 노드도 엔진 상태도 안 본다 — 그래서 헤드리스로 잴 수 있다.
##
## 방향은 **마우스가 정한다. 이동 방향과 별개다** (GDD D-2c) — 왼쪽으로 걸으면서
## 오른쪽을 겨눌 수 있다. 이동은 8방향이지만 **바라보는 방향은 4방향**이다:
## 스프라이트가 앞/뒤/옆 네 장뿐이라 대각선을 표현할 그림이 없다.
##
## **히스테리시스가 왜 필요한가**: 45° 경계에 커서를 두면 1px 만 흔들려도
## 오른쪽↔아래가 매 프레임 뒤집힌다. 60Hz 로 깜빡이는 스프라이트가 된다.
## 그래서 **잡는 각(45°)보다 놓는 각(55°)을 넓게** 둔다 — 한 번 잡은 방향은
## 경계를 10° 넘어가야 놓는다.

## 화면 좌표계다 — y 가 아래로 증가하므로 DOWN 이 화면 아래쪽이다.
const AXES: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

const SNAP_DEG := 45.0          # 축 하나가 가져가는 부채꼴의 반각 (360 / 4 / 2)
const HYSTERESIS_DEG := 10.0    # 이미 잡은 방향을 놓는 데 더 필요한 각
const DEAD_ZONE := 8.0          # 이보다 가까우면 각이 무의미하다 (몸통 반폭 24px 의 1/3)

## 가장 가까운 축. 경계(정확히 45°)에서는 AXES 순서가 정한다 — 결정적이어야 한다.
static func nearest(aim: Vector2) -> Vector2:
	var best := AXES[0]
	var best_a := INF
	for ax in AXES:
		var a := absf(aim.angle_to(ax))
		if a < best_a - 1e-6:
			best_a = a
			best = ax
	return best

## 겨눈 벡터(커서 - 플레이어)와 지금 방향으로 새 방향을 정한다.
## `current` 는 AXES 중 하나이거나 Vector2.ZERO(아직 안 정해짐) 여야 한다.
static func resolve(aim: Vector2, current: Vector2) -> Vector2:
	if aim.length() < DEAD_ZONE:
		return current
	if current == Vector2.ZERO:
		return nearest(aim)
	if absf(aim.angle_to(current)) <= deg_to_rad(SNAP_DEG + HYSTERESIS_DEG):
		return current
	return nearest(aim)
