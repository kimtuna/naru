class_name IslandCliffs
extends RefCounted
## 절벽 — 솟은 지형의 높이 경계 블록 가운데 cliff_percent 만큼을 절벽 블록으로 둔다. spec/03_world/terrain.md.
## 얼룩이 높은 경계부터 골라 절벽이 줄지어 이어진다. 나머지 경계는 걸어 오르는 경사다.
## 보장 (임시): 솟은 덩어리마다 스폰에서 꼭대기까지 절벽을 안 지나는 길이 있고, 절벽이 하나 이상 있다.

const Terrain := IslandConfig.Terrain
const NEIGHBORS_4 := IslandField.NEIGHBORS_4
const NEIGHBORS_8 := IslandField.NEIGHBORS_8
const SALT_CLIFF := 0x68E31DA4

var _blocks: int
var _block: int
var _kind: PackedByteArray
var _height: PackedByteArray
## 블록마다 절벽이면 1.
var cliff := PackedByteArray()
var _boundary := PackedByteArray()
var _noise := PackedFloat64Array()
## 보장 길이 지나는 블록 — 나중에 절벽으로 바꾸지 않는다.
var _kept := PackedByteArray()


## kind · height 는 블록 격자 (blocks × blocks). start 는 스폰 블록.
func _init(seed_value: int, cfg: IslandConfig, blocks: int, kind: PackedByteArray,
		height: PackedByteArray, start: int) -> void:
	_blocks = blocks
	_block = maxi(cfg.terrain_block, 1)
	_kind = kind
	_height = height
	var n := blocks * blocks
	cliff.resize(n)
	_boundary.resize(n)
	_noise.resize(n)
	_kept.resize(n)
	_pick(seed_value, cfg)
	var blobs := _label_blobs()
	_open_paths(start, blobs)
	_ensure_one(blobs)


func _pick(seed_value: int, cfg: IslandConfig) -> void:
	var lat := IslandField.lattice(seed_value, cfg.size, cfg.cliff_noise_cell, SALT_CLIFF)
	var values := PackedFloat64Array()
	var cells := PackedInt32Array()
	for i in _blocks * _blocks:
		if not _is_boundary(i):
			continue
		_boundary[i] = 1
		var c := Vector2(i % _blocks + 0.5, i / _blocks + 0.5) * _block
		_noise[i] = IslandField.noise(lat, cfg.size, cfg.cliff_noise_cell, c)
		cells.append(i)
		values.append(_noise[i])
	var want := roundi(cells.size() * clampf(cfg.cliff_percent / 100.0, 0.0, 1.0))
	var thr := IslandField.top_threshold(values, want)
	for k in cells.size():
		if values[k] >= thr:
			cliff[cells[k]] = 1


## 솟은 블록인데 8방향 이웃에 더 낮은 블록이 있다.
func _is_boundary(i: int) -> bool:
	if not IslandConfig.is_elevated(_kind[i]):
		return false
	for d in NEIGHBORS_8:
		var j := _neighbor(i, d)
		if j >= 0 and _height[j] < _height[i]:
			return true
	return false


func _neighbor(i: int, d: Vector2i) -> int:
	var nx: int = i % _blocks + d.x
	var ny: int = i / _blocks + d.y
	if nx < 0 or ny < 0 or nx >= _blocks or ny >= _blocks:
		return -1
	return ny * _blocks + nx


## 같은 종류로 4방향 이어진 솟은 덩어리들 — 덩어리마다 블록 목록.
func _label_blobs() -> Array[PackedInt32Array]:
	var seen := PackedByteArray()
	seen.resize(_blocks * _blocks)
	var blobs: Array[PackedInt32Array] = []
	for s in _blocks * _blocks:
		if seen[s] == 1 or not IslandConfig.is_elevated(_kind[s]):
			continue
		var blob := PackedInt32Array([s])
		seen[s] = 1
		var k := 0
		while k < blob.size():
			var i := blob[k]
			k += 1
			for d in NEIGHBORS_4:
				var j := _neighbor(i, d)
				if j >= 0 and seen[j] == 0 and _kind[j] == _kind[s]:
					seen[j] = 1
					blob.append(j)
		blobs.append(blob)
	return blobs


## 스폰에서 바다가 아닌 블록으로 4방향 — 절벽에 들어갈 때만 1 드는 최단 길(0-1 BFS).
## 덩어리마다 절벽이 가장 적게 걸리는 꼭대기 블록을 고르고, 그 길의 절벽을 경사로 되돌린다.
func _open_paths(start: int, blobs: Array[PackedInt32Array]) -> void:
	var n := _blocks * _blocks
	var dist := PackedInt32Array()
	dist.resize(n)
	dist.fill(1 << 30)
	var parent := PackedInt32Array()
	parent.resize(n)
	parent.fill(-1)
	# 두 줄 큐 — 비용 0 은 지금 줄, 1 은 다음 줄.
	var now := PackedInt32Array([start])
	dist[start] = 0
	while not now.is_empty():
		var later := PackedInt32Array()
		var k := 0
		while k < now.size():
			var i := now[k]
			k += 1
			for d in NEIGHBORS_4:
				var j := _neighbor(i, d)
				if j < 0 or _kind[j] == Terrain.SEA:
					continue
				var nd := dist[i] + cliff[j]
				if nd < dist[j]:
					dist[j] = nd
					parent[j] = i
					if cliff[j] == 1:
						later.append(j)
					else:
						now.append(j)
		now = later
	for blob in blobs:
		var top := 0
		for i in blob:
			top = maxi(top, _height[i])
		var best := -1
		for i in blob:
			if _height[i] == top and (best < 0 or dist[i] < dist[best]):
				best = i
		var i := best
		while i >= 0:
			cliff[i] = 0
			_kept[i] = 1
			i = parent[i]


## 절벽이 하나도 없는 덩어리 — 길이 안 지나는 경계 가운데 얼룩이 가장 높은 블록을 절벽으로.
func _ensure_one(blobs: Array[PackedInt32Array]) -> void:
	for blob in blobs:
		var best := -1
		for i in blob:
			if cliff[i] == 1:
				best = -2
				break
			if _boundary[i] == 1 and _kept[i] == 0 and (best < 0 or _noise[i] > _noise[best]):
				best = i
		if best >= 0:
			cliff[best] = 1
