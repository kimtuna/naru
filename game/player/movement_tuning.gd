class_name MovementTuning
extends Resource
## 캐릭터 이동 수치 — 이동 속력은 여기 한 곳에만 둔다 (값은 player/movement_tuning.tres).
## spec/02_player/movement-controls.md: 이동 속력 값은 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://player/movement_tuning.tres"

## 초당 픽셀. 8방향 어느 쪽이든 이 속력으로 움직인다.
@export var move_speed := 80.0


static func load_default() -> MovementTuning:
	return load(DEFAULT_PATH) as MovementTuning
