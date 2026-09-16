class_name RegrowthConfig
extends Resource
## 자원 재생 수치 — 한 곳에 모은다 (값은 world/regrowth/regrowth_config.tres).
## spec/03_world/resources-regrowth.md: 주기는 나무 < 돌 < 광물. 날 수 · 둘레 반경은 spec 미정 — 임시 값이다.

const DEFAULT_PATH := "res://world/regrowth/regrowth_config.tres"
const Deposit := IslandConfig.Deposit

## 게임 하루의 초 (spec/03_world/day-night.md: 20분).
@export var day_seconds := 1200.0
## 없앤 뒤 다시 자라기까지의 게임 날 수.
@export var tree_days := 2.0
@export var stone_days := 4.0
@export var ore_days := 8.0
## 설치물에서 이 칸 수 안(가로 · 세로 · 대각선 모두)에는 자라지 않는다.
@export var structure_radius := 3
## 재생할 칸을 이 간격(초)마다 훑는다 — 매 프레임 훑지 않는다.
@export var check_interval := 1.0


static func load_default() -> RegrowthConfig:
	return load(DEFAULT_PATH) as RegrowthConfig


## 자원이 없어진 뒤 다시 자라기까지의 초. 원래 빈 칸(NONE)은 기다릴 것이 없다 — 표시만 바로 지운다.
func period_of(deposit: Deposit) -> float:
	match deposit:
		Deposit.TREE:
			return tree_days * day_seconds
		Deposit.STONE:
			return stone_days * day_seconds
		Deposit.ORE:
			return ore_days * day_seconds
	return 0.0
