class_name IslandConfig
extends Resource
## 섬 생성 수치 — 한 곳에 모은다 (값은 world/island/island_config.tres).
## spec/03_world/island-generation.md: 배치는 「채울 %」 하나 + 종류 사이의 비. 광물은 지형이 정한다.
## 지형 목록 · 광물-지형 대응은 spec 미정 — 프로토타입 값이다 (풀밭 + 광물 지형 1종).

const DEFAULT_PATH := "res://world/island/island_config.tres"

enum Terrain { GRASS, ORE_GROUND }
enum Deposit { NONE, TREE, STONE, ORE }

## 섬 한 변의 타일 수.
@export var size := 256
## 스폰 둘레 빈터의 한 변 (홀수). 스폰은 섬 한가운데.
@export var spawn_clear := 7

## 땅의 몇 %를 자원으로 채우나 (0 ~ 100).
@export_range(0.0, 100.0) var fill_percent := 30.0
## 종류 사이의 비 — 섬 전체에서 센 비다. 광물은 광물 지형에만 나므로 그 안에서는 광물 몫이 커진다.
@export var tree_weight := 3.0
@export var stone_weight := 2.0
@export var ore_weight := 1.0

## 광물 지형 얼룩 — 격자 한 칸의 타일 수와, 섬에서 얼룩이 덮는 %.
## 문턱은 시드마다 이 %가 되게 정한다 — 시드에 따라 광물 지형이 좁아져 비율을 못 맞추는 일이 없다.
## 채울 % × 광물 몫 보다 좁으면 비율을 맞출 수 없다 (ratio_reachable).
@export var ore_noise_cell := 32
@export_range(0.0, 100.0) var ore_ground_percent := 20.0
## 얼룩 넓이를 잴 때 이 간격마다 한 칸씩 본다 (얼룩이 부드러워 전체를 셀 필요가 없다).
@export var ore_sample_step := 4
## 반드시 있는 광물 지형 — 스폰에서 이만큼 떨어진 곳에 이 반지름의 원.
@export var ore_patch_distance := 24
@export var ore_patch_radius := 8


static func load_default() -> IslandConfig:
	return load(DEFAULT_PATH) as IslandConfig


func spawn() -> Vector2i:
	return Vector2i(size / 2, size / 2)


func fill() -> float:
	return clampf(fill_percent / 100.0, 0.0, 1.0)


func total_weight() -> float:
	return maxf(tree_weight, 0.0) + maxf(stone_weight, 0.0) + maxf(ore_weight, 0.0)


## 채운 칸 가운데 광물 몫 (0 ~ 1).
func ore_share() -> float:
	var total := total_weight()
	return maxf(ore_weight, 0.0) / total if total > 0.0 else 0.0


## 광물이 아닌 자원 가운데 나무 몫 (0 ~ 1).
func tree_share_of_rest() -> float:
	var rest := maxf(tree_weight, 0.0) + maxf(stone_weight, 0.0)
	return maxf(tree_weight, 0.0) / rest if rest > 0.0 else 0.0
