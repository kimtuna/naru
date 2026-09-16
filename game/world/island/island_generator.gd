class_name IslandGenerator
extends RefCounted
## 시드 → 섬. 칸의 값은 (시드, 좌표)만으로 정해지는 해시다 — 만드는 순서와 상관없다.
## 재생(「없앤 표시를 지우기」)은 deposit_at 으로 원래 값을 다시 얻는다.

const Terrain := IslandConfig.Terrain
const Deposit := IslandConfig.Deposit

const MASK32 := 0xFFFFFFFF
## 해시 용도마다 다른 소금 — 같은 칸이라도 용도끼리 값이 엮이지 않게.
const SALT_DEPOSIT := 0x1B873593
const SALT_TERRAIN := 0x68E31DA4
const SALT_PATCH := 0x2545F491

var world_seed: int
var config: IslandConfig
var _anchor: Vector2i
## 이 시드에서 얼룩이 광물 지형이 되는 문턱과, 섬에서 광물 지형이 덮는 몫.
var _ore_threshold := 2.0
var _ore_ground_share := 0.0
## 광물 지형 칸이 광물일 확률 · 광물 아닌 칸이 나무/돌일 확률.
var _ore_chance := 0.0
var _rest_chance := 0.0
## 섬 안 격자 꼭짓점의 해시값 — 얼룩을 매번 해시로 구하지 않게.
var _lattice := PackedFloat64Array()
var _lattice_w := 0


func _init(seed_value: int, cfg: IslandConfig = null) -> void:
	world_seed = seed_value
	config = cfg if cfg else IslandConfig.load_default()
	# 스폰에서 맨해튼 거리 ore_patch_distance 인 칸 하나. 정수만 써서 기계마다 같다.
	var dist := config.ore_patch_distance
	var along := int(hash01(world_seed, 0, 0, SALT_PATCH) * (2 * dist + 1))
	var dx := along - dist
	var dy := (dist - absi(dx)) * (1 if hash01(world_seed, 1, 0, SALT_PATCH) < 0.5 else -1)
	_anchor = config.spawn() + Vector2i(dx, dy)
	_build_lattice()
	_measure_ore_ground()
	_compute_chances()
	if not ratio_reachable():
		push_warning("IslandGenerator: 광물 지형(%.3f)이 채울 %% × 광물 몫(%.3f)보다 좁아 비율을 맞출 수 없다"
			% [_ore_ground_share, config.fill() * config.ore_share()])


## 섬 전체를 만든다.
static func generate(seed_value: int, cfg: IslandConfig = null) -> IslandMap:
	var gen := IslandGenerator.new(seed_value, cfg)
	return IslandMap.new(gen)


## 반드시 있는 광물 지형의 한가운데. 이 칸에는 광물이 반드시 있다.
func ore_anchor() -> Vector2i:
	return _anchor


func terrain_at(x: int, y: int) -> Terrain:
	var cell := Vector2i(x, y)
	if cell.distance_squared_to(_anchor) <= config.ore_patch_radius * config.ore_patch_radius:
		return Terrain.ORE_GROUND
	if _ore_noise(x, y) >= _ore_threshold:
		return Terrain.ORE_GROUND
	return Terrain.GRASS


func deposit_at(x: int, y: int) -> Deposit:
	return deposit_on(x, y, terrain_at(x, y))


## 지형을 이미 알 때 — 섬 전체를 만들 때 지형 계산을 두 번 하지 않는다.
## 칸마다 해시값 하나로 정한다. 광물 지형: 광물 확률 _ore_chance, 그 나머지에서 나무/돌 확률 _rest_chance.
## 풀밭: 나무/돌 확률 _rest_chance. 그래서 섬 전체의 채운 % 와 나무:돌:광물 비가 설정대로 나온다.
func deposit_on(x: int, y: int, terrain: Terrain) -> Deposit:
	var cell := Vector2i(x, y)
	if in_spawn_clear(cell):
		return Deposit.NONE
	if cell == _anchor:
		return Deposit.ORE
	var r := hash01(world_seed, x, y, SALT_DEPOSIT)
	if terrain == Terrain.ORE_GROUND:
		if r < _ore_chance:
			return Deposit.ORE
		r = (r - _ore_chance) / (1.0 - _ore_chance)
	if r >= _rest_chance:
		return Deposit.NONE
	return Deposit.TREE if r / _rest_chance < config.tree_share_of_rest() else Deposit.STONE


## 섬에서 광물 지형이 덮는 몫 (표본으로 잰 값).
func ore_ground_share() -> float:
	return _ore_ground_share


## 광물 지형이 넉넉해 섬 전체 비율을 맞출 수 있나.
func ratio_reachable() -> bool:
	return _ore_ground_share + 1e-9 >= config.fill() * config.ore_share()


func in_spawn_clear(cell: Vector2i) -> bool:
	var half := config.spawn_clear / 2
	var d := (cell - config.spawn()).abs()
	return d.x <= half and d.y <= half


func _compute_chances() -> void:
	var fill := config.fill()
	var ore := fill * config.ore_share()
	_ore_chance = minf(ore / _ore_ground_share, 1.0) if _ore_ground_share > 0.0 else 0.0
	if _ore_chance >= 1.0:
		_ore_chance = 1.0 - 1e-9  # 나머지를 나눌 때 0 으로 나누지 않게
	var room := 1.0 - _ore_ground_share * _ore_chance
	_rest_chance = clampf((fill - ore) / room, 0.0, 1.0) if room > 0.0 else 0.0


## 표본 칸의 얼룩값에서 ore_ground_percent 번째 문턱을 고르고, 보장 원까지 넣어 넓이를 잰다.
func _measure_ore_ground() -> void:
	var step := maxi(config.ore_sample_step, 1)
	var samples := PackedFloat64Array()
	var cells: Array[Vector2i] = []
	for y in range(0, config.size, step):
		for x in range(0, config.size, step):
			samples.append(_ore_noise(x, y))
			cells.append(Vector2i(x, y))
	var sorted := samples.duplicate()
	sorted.sort()
	var n := sorted.size()
	var k := roundi(n * clampf(config.ore_ground_percent / 100.0, 0.0, 1.0))
	_ore_threshold = 2.0 if k <= 0 else float(sorted[n - k])
	var r2 := config.ore_patch_radius * config.ore_patch_radius
	var inside := 0
	for i in n:
		if samples[i] >= _ore_threshold or cells[i].distance_squared_to(_anchor) <= r2:
			inside += 1
	_ore_ground_share = float(inside) / n if n > 0 else 0.0


func _build_lattice() -> void:
	var s := maxi(config.ore_noise_cell, 1)
	_lattice_w = ceili(float(config.size) / s) + 2
	_lattice.resize(_lattice_w * _lattice_w)
	for gy in _lattice_w:
		for gx in _lattice_w:
			_lattice[gy * _lattice_w + gx] = hash01(world_seed, gx, gy, SALT_TERRAIN)


func _lattice_at(gx: int, gy: int) -> float:
	if gx >= 0 and gy >= 0 and gx < _lattice_w and gy < _lattice_w:
		return _lattice[gy * _lattice_w + gx]
	return hash01(world_seed, gx, gy, SALT_TERRAIN)


## 격자 꼭짓점마다 해시값을 두고 부드럽게 이은 얼룩 (0 ~ 1).
func _ore_noise(x: int, y: int) -> float:
	var s := maxi(config.ore_noise_cell, 1)
	var gx := floori(float(x) / s)
	var gy := floori(float(y) / s)
	var tx := smoothstep(0.0, 1.0, float(x - gx * s) / s)
	var ty := smoothstep(0.0, 1.0, float(y - gy * s) / s)
	var a := _lattice_at(gx, gy)
	var b := _lattice_at(gx + 1, gy)
	var c := _lattice_at(gx, gy + 1)
	var d := _lattice_at(gx + 1, gy + 1)
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


## (시드, x, y, 소금) → [0, 1). 64비트 곱셈 넘침에 기대지 않게 32비트로 나눠 섞는다.
static func hash01(seed_value: int, x: int, y: int, salt: int) -> float:
	var h := _mix(seed_value & MASK32)
	h = _mix(h ^ ((seed_value >> 32) & MASK32))
	h = _mix(h ^ (x & MASK32))
	h = _mix(h ^ (y & MASK32))
	h = _mix(h ^ (salt & MASK32))
	return float(h) / 4294967296.0


## lowbias32 (Chris Wellons).
static func _mix(v: int) -> int:
	v ^= v >> 16
	v = _mul32(v, 0x7feb352d)
	v ^= v >> 15
	v = _mul32(v, 0x846ca68b)
	v ^= v >> 16
	return v


static func _mul32(a: int, b: int) -> int:
	var lo := a * (b & 0xFFFF)
	var hi := ((a * (b >> 16)) & 0xFFFF) << 16
	return (lo + hi) & MASK32
