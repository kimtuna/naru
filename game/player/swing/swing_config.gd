class_name SwingConfig
extends Resource
## 좌클릭 평타 수치 — 휘두르는 간격 · 손이 닿는 거리 · 맞는 부채꼴을 한 곳에 모은다 (값은 player/swing/swing_config.tres).
## spec/02_player/movement-controls.md: 손이 닿는 거리 값은 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://player/swing/swing_config.tres"

## 좌클릭을 쥐고 있으면 이 간격(초)마다 한 번씩 휘두른다.
@export var swing_interval := 0.35
## 손이 닿는 거리 — 캐릭터 한가운데에서 대상 한가운데까지 (타일 수). 제작대 열기 · 설치도 같은 값을 쓴다.
@export var reach_tiles := 2.0
## 바라보는 방향 앞으로 맞는 부채꼴의 전체 각도 (도).
@export var arc_degrees := 120.0
## 휘두른 표시가 보이는 시간(초).
@export var show_time := 0.15


static func load_default() -> SwingConfig:
	return load(DEFAULT_PATH) as SwingConfig


func reach_px(tile_px: int) -> float:
	return reach_tiles * tile_px


func half_arc() -> float:
	return deg_to_rad(arc_degrees) / 2.0
