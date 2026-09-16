class_name FarmConfig
extends Resource
## 농사 수치 — 한 곳에 모은다 (값은 life/farming/farm_config.tres).
## spec/04_life/farming.md: 첫 작물은 밀, 3일에 자란다 (사람 결정). 수확 수 · 물 마름 규칙은 미정 — 임시 값이다.
## 물은 하루치다 — 물 준 날이 넘어가야 하루 자라고, 다음 날 다시 줘야 한다 (임시 규칙).

const DEFAULT_PATH := "res://life/farming/farm_config.tres"

## 들고 우클릭하면 간 밭에 심는다 — 하나를 쓴다.
@export var seed_id := "wheat_seed"
## 들고 우클릭하면 심은 작물에 물을 준다 — 닳지 않는다.
@export var watering_can_id := "watering_can"
## 다 자란 작물을 수확하면 떨어지는 아이템.
@export var crop_id := "wheat"
## 다 자라기까지 물을 받고 넘긴 날 수.
@export var grow_days := 3
## 수확 한 번에 떨어지는 수.
@export var harvest_count := 1


static func load_default() -> FarmConfig:
	return load(DEFAULT_PATH) as FarmConfig
