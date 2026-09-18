class_name TilePalette
extends RefCounted
## 섬 칸을 그리는 색 · 그림자 세기 — 한 곳에 모은다 (임시 값, 아트는 사람이 나중에 넣는다).
## 3/4 시점 시험 (G-015): 윗면 · 절벽 앞면 · 윗가장자리 · 옆면 · 경사 · 그림자를 색 네모로 구별한다.

## 윗면 — 지형마다 다른 색, 높이 한 단마다 조금씩 밝게.
const TERRAIN := {
	IslandConfig.Terrain.GRASS: Color(0.33, 0.55, 0.3),
	IslandConfig.Terrain.FOREST: Color(0.2, 0.42, 0.22),
	IslandConfig.Terrain.MOUNTAIN: Color(0.45, 0.4, 0.34),
	IslandConfig.Terrain.VOLCANO: Color(0.42, 0.2, 0.16),
	IslandConfig.Terrain.SNOW: Color(0.72, 0.78, 0.82),
	IslandConfig.Terrain.BEACH: Color(0.82, 0.76, 0.5),
	IslandConfig.Terrain.SEA: Color(0.16, 0.34, 0.6),
}
const HEIGHT_LIGHTEN := 0.06

## 절벽 앞면 — 윗면 색을 이만큼 어둡게 한 띠를 위에서 아래로 (위가 밝다). 띠 개수.
const FRONT_TOP_DARKEN := 0.25
const FRONT_BOTTOM_DARKEN := 0.6
const FRONT_BANDS := 4
## 벽 높이를 셀 때 위 · 아래로 이만큼 칸까지만 본다.
const FRONT_RUN_MAX := 4
## 앞면 아래쪽 그림자 — 벽 발치 띠 두께 (칸 비율) · 색.
const FRONT_FOOT := 0.2
const FRONT_FOOT_COLOR := Color(0.05, 0.04, 0.04)
## 절벽 윗가장자리 — 얇은 선 두께 (픽셀) · 색.
const TOP_EDGE_PX := 2.0
const TOP_EDGE_COLOR := Color(0.1, 0.08, 0.08)
## 절벽 옆면 — 윗면을 이만큼 어둡게 + 벽 쪽 세로 띠 (칸 비율) · 띠 어둡기.
const SIDE_DARKEN := 0.2
const SIDE_STRIP := 0.35
const SIDE_STRIP_DARKEN := 0.5
## 경사 — 윗면 위에 밝은 가로 줄 (계단 느낌) 개수 · 두께 · 밝기.
const SLOPE_LINES := 2
const SLOPE_LINE_PX := 1.0
const SLOPE_LIGHTEN := 0.25
## 높은 땅 남쪽 아래 칸의 그림자 — 칸 위쪽 띠 두께 (칸 비율) · 색 (알파가 세기).
const SHADOW_DEPTH := 0.4
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)

const DEPOSIT := {
	IslandConfig.Deposit.TREE: Color(0.1, 0.35, 0.12),
	IslandConfig.Deposit.STONE: Color(0.55, 0.55, 0.58),
	IslandConfig.Deposit.IRON: Color(0.62, 0.45, 0.38),
	IslandConfig.Deposit.SULFUR: Color(0.9, 0.85, 0.2),
	IslandConfig.Deposit.HERB: Color(0.45, 0.8, 0.45),
}


## 윗면 색 — 지형 색을 높이만큼 밝게.
static func top(terrain: int, height: int) -> Color:
	return (TERRAIN[terrain] as Color).lightened(HEIGHT_LIGHTEN * height)
