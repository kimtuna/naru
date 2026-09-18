class_name TileLook
extends RefCounted
## 칸을 어떻게 그릴지 — 이웃 높이만 보고 고르는 순수 함수 (3/4 시점 시험, G-015). 판정 코드와 상관없다.
## 화면 위가 북쪽이다. 절벽 칸:
##   북쪽 이웃이 더 높다 → 앞면 (보는 쪽으로 선 벽) · 남쪽 이웃이 더 높다 → 윗가장자리 · 동 · 서만 높다 → 옆면.
##   더 높은 4방향 이웃이 없으면 (절벽 블록의 바깥 줄) 더 낮은 이웃 쪽으로 같은 규칙: 남쪽이 낮으면 앞면,
##   북쪽이 낮으면 윗가장자리, 동 · 서만 낮으면 옆면. 대각선만 낮으면 그 대각선의 남북으로 가르고, 아무 차이도 없으면 옆면.
## 절벽이 아닌 칸: 8방향 이웃 가운데 더 낮은 칸이 있으면 경사, 없으면 평면.

enum Look { FLAT, CLIFF_FRONT, CLIFF_TOP, CLIFF_SIDE, SLOPE }
## 이웃 순서 — pick 의 around 가 이 순서다.
enum Dir { N, S, E, W, NE, NW, SE, SW }
const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1),
]


## cliff: 이 칸이 절벽인가 · height: 이 칸 높이 · around: Dir 순서의 이웃 8칸 높이.
static func pick(cliff: bool, height: int, around: PackedInt32Array) -> Look:
	var d := PackedInt32Array()
	for h in around:
		d.append(h - height)
	if not cliff:
		for v in d:
			if v < 0:
				return Look.SLOPE
		return Look.FLAT
	if d[Dir.N] > 0:
		return Look.CLIFF_FRONT
	if d[Dir.S] > 0:
		return Look.CLIFF_TOP
	if d[Dir.E] > 0 or d[Dir.W] > 0:
		return Look.CLIFF_SIDE
	if d[Dir.S] < 0:
		return Look.CLIFF_FRONT
	if d[Dir.N] < 0:
		return Look.CLIFF_TOP
	if d[Dir.E] < 0 or d[Dir.W] < 0:
		return Look.CLIFF_SIDE
	if d[Dir.SE] < 0 or d[Dir.SW] < 0:
		return Look.CLIFF_FRONT
	if d[Dir.NE] < 0 or d[Dir.NW] < 0:
		return Look.CLIFF_TOP
	return Look.CLIFF_SIDE


## 그림자가 지나 — 절벽이 아닌 칸인데 북쪽 이웃이 더 높거나, 북쪽 이웃이 절벽 앞면이다 (벽 발치).
static func shadowed(cliff: bool, height: int, north_height: int, north_look: Look) -> bool:
	return not cliff and (north_height > height or north_look == Look.CLIFF_FRONT)


## 옆면 벽이 어느 쪽인가 — +1 동 · -1 서. 더 높은 쪽, 없으면 더 낮은 쪽, 둘 다 없으면 0.
static func side_of(height: int, around: PackedInt32Array) -> int:
	var e := around[Dir.E] - height
	var w := around[Dir.W] - height
	if e > 0 or w > 0:
		return 1 if e >= w else -1
	if e < 0 or w < 0:
		return 1 if e <= w else -1
	return 0


## 지도에서 이웃 8칸 높이 — 섬 밖 이웃은 이 칸과 같은 높이로 본다.
static func around_of(map: IslandMap, cell: Vector2i) -> PackedInt32Array:
	var own := map.height_at(cell)
	var out := PackedInt32Array()
	for o in OFFSETS:
		var c := cell + o
		out.append(map.height_at(c) if map.has_cell(c) else own)
	return out


static func of(map: IslandMap, cell: Vector2i) -> Look:
	return pick(map.is_cliff(cell), map.height_at(cell), around_of(map, cell))


static func shadow_at(map: IslandMap, cell: Vector2i) -> bool:
	var north := cell + Vector2i.UP
	if not map.has_cell(north):
		return false
	return shadowed(map.is_cliff(cell), map.height_at(cell), map.height_at(north), of(map, north))
