class_name IslandField
extends RefCounted
## 섬 생성에 쓰는 격자 도구 — 부드러운 얼룩 · 상위 몇 개 문턱 · 번짐.

const NEIGHBORS_4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const NEIGHBORS_8 := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1),
]


## 격자 꼭짓점마다 해시값 — 얼룩을 매번 해시로 구하지 않게.
static func lattice(seed_value: int, size: int, cell: int, salt: int) -> PackedFloat64Array:
	var w := _lattice_width(size, cell)
	var lat := PackedFloat64Array()
	lat.resize(w * w)
	for gy in w:
		for gx in w:
			lat[gy * w + gx] = IslandGenerator.hash01(seed_value, gx, gy, salt)
	return lat


## 격자 꼭짓점 값을 부드럽게 이은 얼룩 (0 ~ 1). p 는 섬 안 좌표 (0 ≤ p < size).
static func noise(lat: PackedFloat64Array, size: int, cell: int, p: Vector2) -> float:
	var s := float(maxi(cell, 1))
	var w := _lattice_width(size, cell)
	var gx := floori(p.x / s)
	var gy := floori(p.y / s)
	var tx := smoothstep(0.0, 1.0, p.x / s - gx)
	var ty := smoothstep(0.0, 1.0, p.y / s - gy)
	var i := gy * w + gx
	return lerpf(lerpf(lat[i], lat[i + 1], tx), lerpf(lat[i + w], lat[i + w + 1], tx), ty)


static func _lattice_width(size: int, cell: int) -> int:
	return ceili(float(size) / maxi(cell, 1)) + 2


## 값 가운데 큰 쪽 count 개를 고르는 문턱 (값 >= 문턱). count 가 0 이하면 아무것도 안 고른다.
static func top_threshold(values: PackedFloat64Array, count: int) -> float:
	if count <= 0 or values.is_empty():
		return INF
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[maxi(sorted.size() - count, 0)]


## width × width 격자에서 starts 부터 mask[i] == want 인 칸으로 4방향 번짐. 닿은 칸이 1.
static func flood(width: int, starts, mask: PackedByteArray, want: int) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(width * width)
	var stack := PackedInt32Array()
	for i in starts:
		if mask[i] == want and seen[i] == 0:
			seen[i] = 1
			stack.append(i)
	while not stack.is_empty():
		var i := stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		var x := i % width
		var y := i / width
		for d in NEIGHBORS_4:
			var nx: int = x + d.x
			var ny: int = y + d.y
			if nx < 0 or ny < 0 or nx >= width or ny >= width:
				continue
			var j := ny * width + nx
			if mask[j] == want and seen[j] == 0:
				seen[j] = 1
				stack.append(j)
	return seen
