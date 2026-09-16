class_name LightingConfig
extends Resource
## 밝기 수치 — 한 곳에 모은다 (값은 world/lighting/lighting_config.tres).
## spec/03_world/day-night.md: 밤은 램프가 값을 할 만큼 어둡되, 못 나갈 만큼은 아니다.
## 밤 밝기 · 광원 반경은 spec 미정 — 임시 값이다.

const DEFAULT_PATH := "res://world/lighting/lighting_config.tres"

## 낮의 화면 밝기 (1 = 그대로).
@export_range(0.0, 1.0) var day_brightness := 1.0
## 밤의 화면 밝기.
@export_range(0.0, 1.0) var night_brightness := 0.3
## 램프 반경 (월드 픽셀). 이 거리 밖은 램프가 없을 때와 같다.
@export var lamp_radius := 96.0


static func load_default() -> LightingConfig:
	return load(DEFAULT_PATH) as LightingConfig
