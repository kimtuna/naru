class_name IslandGenerator
extends RefCounted
## 시드 → 섬. 칸의 값은 (시드, 좌표)만으로 정해진다 — 만드는 순서와 상관없다.
## 지형 · 높이는 IslandTerrain, 자원은 칸마다 해시.
## 재생(「없앤 표시를 지우기」)은 deposit_at 으로 원래 값을 다시 얻는다.

const Terrain := IslandConfig.Terrain
const Deposit := IslandConfig.Deposit

const MASK32 := 0xFFFFFFFF
## 해시 용도마다 다른 소금 — 같은 칸이라도 용도끼리 값이 엮이지 않게.
const SALT_DEPOSIT := 0x1B873593

var world_seed: int
var config: IslandConfig
## 지형 · 높이 (섬 전체를 한 번에 정한 블록 격자).
var terrain: IslandTerrain
var _anchor: Vector2i
## 땅에서 솟은 지형(광물 지형)이 덮는 몫.
var _ore_ground_share := 0.0
## 광물 지형 칸이 광물일 확률 · 광물 아닌 땅 칸이 나무/돌일 확률.
var _ore_chance := 0.0
var _rest_chance := 0.0


func _init(seed_value: int, cfg: IslandConfig = null) -> void:
	world_seed = seed_value
	config = cfg if cfg else IslandConfig.load_default()
	terrain = IslandTerrain.new(world_seed, config)
	_anchor = terrain.peak(Terrain.MOUNTAIN)
	if terrain.land_cells > 0:
		_ore_ground_share = float(terrain.elevated_cells) / terrain.land_cells
	_compute_chances()
	if not ratio_reachable():
		push_warning("IslandGenerator: 광물 지형(%.3f)이 채울 %% × 광물 몫(%.3f)보다 좁아 비율을 맞출 수 없다"
			% [_ore_ground_share, config.fill() * config.ore_share()])


## 섬 전체를 만든다.
static func generate(seed_value: int, cfg: IslandConfig = null) -> IslandMap:
	var gen := IslandGenerator.new(seed_value, cfg)
	return IslandMap.new(gen)


## 반드시 있는 산의 한가운데. 이 칸에는 광물이 반드시 있다.
func ore_anchor() -> Vector2i:
	return _anchor


## 반드시 있는 산 · 화산 · 설산의 한가운데.
func peak(kind: Terrain) -> Vector2i:
	return terrain.peak(kind)


func terrain_at(x: int, y: int) -> Terrain:
	return terrain.terrain_at(x, y)


func height_at(x: int, y: int) -> int:
	return terrain.height_at(x, y)


func cliff_at(x: int, y: int) -> bool:
	return terrain.cliff_at(x, y)


func deposit_at(x: int, y: int) -> Deposit:
	return deposit_on(x, y, terrain_at(x, y))


## 지형을 이미 알 때 — 섬 전체를 만들 때 지형 계산을 두 번 하지 않는다.
## 칸마다 해시값 하나로 정한다. 광물 지형: 광물 확률 _ore_chance, 그 나머지에서 나무/돌 확률 _rest_chance.
## 다른 땅: 나무/돌 확률 _rest_chance. 바다: 없음. 그래서 땅 전체의 채운 % 와 나무:돌:광물 비가 설정대로 나온다.
func deposit_on(x: int, y: int, kind: Terrain) -> Deposit:
	var cell := Vector2i(x, y)
	if kind == Terrain.SEA or in_spawn_clear(cell):
		return Deposit.NONE
	if cell == _anchor:
		return Deposit.ORE
	var r := hash01(world_seed, x, y, SALT_DEPOSIT)
	if IslandConfig.is_elevated(kind):
		if r < _ore_chance:
			return Deposit.ORE
		r = (r - _ore_chance) / (1.0 - _ore_chance)
	if r >= _rest_chance:
		return Deposit.NONE
	return Deposit.TREE if r / _rest_chance < config.tree_share_of_rest() else Deposit.STONE


## 땅에서 광물 지형이 덮는 몫.
func ore_ground_share() -> float:
	return _ore_ground_share


## 광물 지형이 넉넉해 땅 전체 비율을 맞출 수 있나.
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
