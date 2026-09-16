class_name IslandConfig
extends Resource
## 섬 생성 수치 — 한 곳에 모은다 (값은 world/island/island_config.tres).
## spec/03_world/island-generation.md: 배치는 지형마다 「채울 %」 하나 + 종류 사이의 비 (DepositRule). 광물은 지형이 정한다.
## 지형 종류 · 높이 규칙은 spec/03_world/terrain.md. 광물: 설산 둘레 = 철 · 화산 둘레 = 유황. 약초는 절벽 칸에만.

const DEFAULT_PATH := "res://world/island/island_config.tres"

## GRASS 가 평지. MOUNTAIN · VOLCANO · SNOW 가 솟은 지형이다.
enum Terrain { GRASS, FOREST, MOUNTAIN, VOLCANO, SNOW, BEACH, SEA }
## 값은 저장 · 비교에 쓰이니 순서를 바꾸지 않는다 (IRON 은 예전의 「광물 1종」 자리).
enum Deposit { NONE, TREE, STONE, IRON, SULFUR, HERB }

## 지형 → 날 수 있는 자원. 여기 없는 종류는 규칙에 비를 적어도 안 난다 — 광물이 제 지형 밖에 안 나게.
const ALLOWED_DEPOSITS := {
	Terrain.GRASS: [Deposit.TREE, Deposit.STONE],
	Terrain.FOREST: [Deposit.TREE, Deposit.STONE],
	Terrain.MOUNTAIN: [Deposit.TREE, Deposit.STONE],
	Terrain.VOLCANO: [Deposit.STONE, Deposit.SULFUR],
	Terrain.SNOW: [Deposit.TREE, Deposit.STONE, Deposit.IRON],
	Terrain.BEACH: [Deposit.TREE, Deposit.STONE],
	Terrain.SEA: [],
}
## 절벽 칸에는 약초만 난다 (spec/04_life/gathering.md).
const CLIFF_DEPOSITS := [Deposit.HERB]
## 광물 → 나는 지형.
const MINERAL_TERRAIN := {Deposit.IRON: Terrain.SNOW, Deposit.SULFUR: Terrain.VOLCANO}

## 섬 한 변의 타일 수.
@export var size := 256
## 스폰 둘레 빈터의 한 변 (홀수). 스폰은 섬 한가운데.
@export var spawn_clear := 7
## 섬을 만들고 그리는 덩어리 한 변의 타일 수 — 게임은 보이는 덩어리만 만든다.
@export var chunk_size := 16

@export_group("View")
## 타일 한 칸의 픽셀.
@export var tile_px := 16
## 화면 가장자리 밖으로 미리 만들어 둘 여유 (픽셀). 이보다 한 덩어리 더 멀어지면 치운다.
@export var view_margin_px := 160.0
@export_group("")

@export_group("Deposits")
## 지형마다 자원 비율 규칙 (절벽 칸은 지형과 상관없이 cliff_deposits). 바다에는 자원이 없다.
@export var grass_deposits: DepositRule
@export var forest_deposits: DepositRule
@export var mountain_deposits: DepositRule
@export var volcano_deposits: DepositRule
@export var snow_deposits: DepositRule
@export var beach_deposits: DepositRule
@export var cliff_deposits: DepositRule
## 빈손 시작 보장 — 스폰 동쪽에 나무, 서쪽에 돌을 이 크기(가로 × 세로 칸)의 덩이로 반드시 둔다.
## 첫 도구 · 첫 제작대 재료(맨손 레시피)가 시작 섬에서 반드시 나오게. 덩이는 스폰 빈터 바로 바깥 한 칸 띄워 둔다.
@export var starter_patch := Vector2i(3, 5)
@export_group("")

@export_group("Terrain")
## 지형을 정하는 가장 작은 네모 한 변 (칸). 2 이상이면 어느 칸이든 같은 지형 이웃이 3칸 이상이다.
@export_range(2, 8) var terrain_block := 2
## 섬(바다 아닌 곳)이 지도에서 덮는 %.
@export_range(0.0, 100.0) var land_percent := 55.0
## 지도 가장자리에서 이 칸 수 안은 반드시 바다.
@export var sea_margin := 12
## 바다에서 이 블록 수 안의 땅이 해안이다.
@export_range(1, 8) var beach_width := 1
## 섬 모양 얼룩 — 큰 얼룩 한 변 · 잔 얼룩 한 변 (칸) · 잔 얼룩 몫 · 가운데에서 멀어질수록 깎는 세기.
@export var shape_noise_cell := 64
@export var shape_detail_cell := 16
@export_range(0.0, 1.0) var shape_detail := 0.35
@export var shape_falloff := 1.2
## 솟은 지형 · 숲 얼룩 한 변 (칸).
@export var relief_noise_cell := 24
@export var forest_noise_cell := 20
## 땅 가운데 솟은 지형(산 · 화산 · 설산)이 덮는 %.
@export_range(0.0, 100.0) var elevated_percent := 20.0
## 솟은 덩어리 하나가 어느 지형이 될지의 비 — 산 : 화산 : 설산.
@export var mountain_weight := 2.0
@export var volcano_weight := 1.0
@export var snow_weight := 1.0
## 땅 가운데 숲이 덮는 %.
@export_range(0.0, 100.0) var forest_percent := 25.0
## 높이 단 수 — 솟은 지형 가장자리가 1, 안으로 한 블록마다 1씩, 이 값까지. 개인 섬 산은 낮다.
@export_range(1, 16) var max_height := 3
## 높이 경계 블록 가운데 절벽인 % — 나머지는 걸어 오르는 경사. 절벽 얼룩 한 변 (칸).
@export_range(0.0, 100.0) var cliff_percent := 50.0
@export var cliff_noise_cell := 12
## 스폰 둘레 이 칸 수 안은 평지(풀밭).
@export var spawn_flat_radius := 8
## 반드시 있는 산 · 화산 · 설산 — 스폰에서 이만큼 떨어진 곳에 이 반지름(칸)의 원 하나씩.
@export var peak_patch_distance := 24
@export var peak_patch_radius := 8
@export_group("")


static func load_default() -> IslandConfig:
	return load(DEFAULT_PATH) as IslandConfig


func spawn() -> Vector2i:
	return Vector2i(size / 2, size / 2)


## 지형의 자원 규칙. 절벽 칸이면 cliff_deposits. 없으면 빈 규칙.
func deposit_rule(terrain: int, cliff := false) -> DepositRule:
	var rule: DepositRule = null
	if cliff:
		rule = cliff_deposits
	else:
		match terrain:
			Terrain.GRASS:
				rule = grass_deposits
			Terrain.FOREST:
				rule = forest_deposits
			Terrain.MOUNTAIN:
				rule = mountain_deposits
			Terrain.VOLCANO:
				rule = volcano_deposits
			Terrain.SNOW:
				rule = snow_deposits
			Terrain.BEACH:
				rule = beach_deposits
	return rule if rule else DepositRule.create(0.0, {})


## 이 칸(지형 · 절벽)에 날 수 있는 자원.
static func allowed_deposits(terrain: int, cliff := false) -> Array:
	return CLIFF_DEPOSITS if cliff else ALLOWED_DEPOSITS.get(terrain, [])


## 규칙마다 따로 복사한 설정 — 테스트가 규칙을 바꿔도 기본 설정이 흔들리지 않게.
func copy() -> IslandConfig:
	var cfg: IslandConfig = duplicate()
	for key in ["grass_deposits", "forest_deposits", "mountain_deposits", "volcano_deposits", "snow_deposits",
			"beach_deposits", "cliff_deposits"]:
		var rule: DepositRule = get(key)
		if rule:
			cfg.set(key, rule.duplicate())
	return cfg


## 솟은 지형(산 · 화산 · 설산)인가.
static func is_elevated(terrain: int) -> bool:
	return terrain == Terrain.MOUNTAIN or terrain == Terrain.VOLCANO or terrain == Terrain.SNOW


func elevated_weights() -> Array[float]:
	return [maxf(mountain_weight, 0.0), maxf(volcano_weight, 0.0), maxf(snow_weight, 0.0)]
