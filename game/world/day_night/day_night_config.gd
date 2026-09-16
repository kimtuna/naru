class_name DayNightConfig
extends Resource
## 낮과 밤 수치 — 한 곳에 모은다 (값은 world/day_night/day_night_config.tres).
## spec/03_world/day-night.md: 하루 20분 = 낮 10분 + 밤 10분.

const DEFAULT_PATH := "res://world/day_night/day_night_config.tres"

## 게임 하루의 초.
@export var day_seconds := 1200.0
## 하루가 시작하고 이 초까지가 낮, 그 뒤가 밤.
@export var daytime_seconds := 600.0


static func load_default() -> DayNightConfig:
	return load(DEFAULT_PATH) as DayNightConfig
