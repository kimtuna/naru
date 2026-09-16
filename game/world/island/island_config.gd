class_name IslandConfig
extends Resource
## 섬 생성 수치 — 한 곳에 모은다 (값은 world/island/island_config.tres).
## spec/03_world/island-generation.md: 배치는 「채울 %」 하나 + 종류 사이의 비. 광물은 지형이 정한다.
## 지형 종류 · 높이 규칙은 spec/03_world/terrain.md. 광물-지형 대응은 아직 프로토타입 — 솟은 지형(산 · 화산 · 설산)에만 광물.

const DEFAULT_PATH := "res://world/island/island_config.tres"

## GRASS 가 평지. MOUNTAIN · VOLCANO · SNOW 가 솟은 지형이다.
enum Terrain { GRASS, FOREST, MOUNTAIN, VOLCANO, SNOW, BEACH, SEA }
enum Deposit { NONE, TREE, STONE, ORE }

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

## 땅의 몇 %를 자원으로 채우나 (0 ~ 100).
@export_range(0.0, 100.0) var fill_percent := 30.0
## 종류 사이의 비 — 섬 전체에서 센 비다. 광물은 광물 지형에만 나므로 그 안에서는 광물 몫이 커진다.
@export var tree_weight := 3.0
@export var stone_weight := 2.0
@export var ore_weight := 1.0

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
## 땅 가운데 솟은 지형(산 · 화산 · 설산)이 덮는 %. 광물은 여기에만 나므로 광물 지형 넓이이기도 하다.
## 채울 % × 광물 몫 보다 좁으면 비율을 맞출 수 없다 (ratio_reachable).
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


## 솟은 지형(산 · 화산 · 설산)인가. 광물은 여기에만 난다.
static func is_elevated(terrain: int) -> bool:
	return terrain == Terrain.MOUNTAIN or terrain == Terrain.VOLCANO or terrain == Terrain.SNOW


func elevated_weights() -> Array[float]:
	return [maxf(mountain_weight, 0.0), maxf(volcano_weight, 0.0), maxf(snow_weight, 0.0)]
