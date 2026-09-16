class_name ClimbingConfig
extends Resource
## 등반 수치 — 기력 · 색 경계 · 빨강 여유량 · 절벽 이동 속력 · 낙하 피해를 한 곳에 모은다
## (값은 life/climbing/climbing_config.tres). spec/04_life/climbing.md: 값은 미정 — 임시 값이다.

const DEFAULT_PATH := "res://life/climbing/climbing_config.tres"
## 절벽 칸 충돌이 올라가는 물리 레이어 번호 — 스파이크를 끼면 캐릭터가 이 레이어를 무시한다.
const CLIFF_LAYER := 2

## 기력 최대치. 절벽 밖에서 이만큼까지 차오른다.
@export var max_stamina := 100.0
## 절벽에서 움직이는 동안 초당 주는 기력. 멈춰 있으면 줄지 않는다 (임시).
@export var drain_per_second := 20.0
## 갈고리총에 매달린 동안 초당 주는 기력 — 움직이지 않아도 준다 (임시).
@export var hang_drain_per_second := 10.0
## 절벽 밖에서 초당 차오르는 기력 (임시).
@export var regen_per_second := 40.0
## 앵커가 달린 칸에서 초당 차오르는 기력 (임시).
@export var anchor_regen_per_second := 30.0
## 남은 기력 비율이 이보다 낮으면 주황, red_below 보다 낮으면 빨강. 그 위는 초록.
@export_range(0.0, 1.0) var orange_below := 0.6
@export_range(0.0, 1.0) var red_below := 0.3
## 빨강 여유 — 기력이 0 이 된 뒤에도 이만큼(기력 단위) 더 움직여야 떨어진다.
@export var grace := 20.0
## 절벽 칸에서의 이동 속력 (초당 픽셀). 경사 배율 대신 이 값을 쓴다.
@export var climb_speed := 40.0
## 떨어지는 속력 (초당 픽셀).
@export var fall_speed := 240.0
## 한 번 떨어질 때 받는 낙하 피해.
@export var fall_damage := 20.0


static func load_default() -> ClimbingConfig:
	return load(DEFAULT_PATH) as ClimbingConfig
