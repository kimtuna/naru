class_name MovementTuning
extends Resource
## 캐릭터 이동 수치 — 이동 속력은 여기 한 곳에만 둔다 (값은 player/movement_tuning.tres).
## spec/02_player/movement-controls.md: 이동 속력 값은 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://player/movement_tuning.tres"

## 초당 픽셀. 8방향 어느 쪽이든 이 속력으로 움직인다.
@export var move_speed := 80.0
## 경사 배율 (spec/03_world/terrain.md) — 오르막은 느리게, 내리막은 빠르게, 평지는 1. 임시 값이다.
@export var uphill_multiplier := 0.7
@export var downhill_multiplier := 1.3


## 경사 방향(+1 오르막 · 0 평지 · -1 내리막)에 맞는 배율.
func slope_multiplier(slope: int) -> float:
	if slope > 0:
		return uphill_multiplier
	if slope < 0:
		return downhill_multiplier
	return 1.0


static func load_default() -> MovementTuning:
	return load(DEFAULT_PATH) as MovementTuning
