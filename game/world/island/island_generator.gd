class_name IslandGenerator
extends RefCounted
## 시드 → 섬. 칸의 값은 (시드, 좌표)만으로 정해진다 — 만드는 순서와 상관없다.
## 지형 · 높이는 IslandTerrain, 자원은 칸마다 해시 하나를 그 칸 지형의 규칙(DepositRule)에 대어 정한다.
## 재생(「없앤 표시를 지우기」)은 deposit_at 으로 원래 값을 다시 얻는다.

const Terrain := IslandConfig.Terrain
const Deposit := IslandConfig.Deposit

const MASK32 := 0xFFFFFFFF
## 해시 용도마다 다른 소금 — 같은 칸이라도 용도끼리 값이 엮이지 않게.
const SALT_DEPOSIT := 0x1B873593
## 절벽 칸 규칙을 _rules 에서 찾는 열쇠 (지형 값과 겹치지 않게).
const CLIFF_KEY := -1

var world_seed: int
var config: IslandConfig
## 지형 · 높이 (섬 전체를 한 번에 정한 블록 격자).
var terrain: IslandTerrain
## 광물 → 반드시 그 광물이 있는 칸 (그 지형 보장 봉우리의 한가운데).
var _mineral_anchors := {}
## 지형(또는 CLIFF_KEY) → [채울 몫, [[종류, 누적 몫]]].
var _rules := {}


func _init(seed_value: int, cfg: IslandConfig = null) -> void:
	world_seed = seed_value
	config = cfg if cfg else IslandConfig.load_default()
	terrain = IslandTerrain.new(world_seed, config)
	for mineral in IslandConfig.MINERAL_TERRAIN:
		_mineral_anchors[mineral] = terrain.peak(IslandConfig.MINERAL_TERRAIN[mineral])
	for kind in IslandConfig.ALLOWED_DEPOSITS:
		_rules[kind] = _compile(config.deposit_rule(kind), IslandConfig.allowed_deposits(kind))
	_rules[CLIFF_KEY] = _compile(config.deposit_rule(Terrain.GRASS, true), IslandConfig.CLIFF_DEPOSITS)


## 섬 전체를 만든다.
static func generate(seed_value: int, cfg: IslandConfig = null) -> IslandMap:
	var gen := IslandGenerator.new(seed_value, cfg)
	return IslandMap.new(gen)


## 이 광물(철 · 유황)이 반드시 있는 칸.
func mineral_anchor(mineral: Deposit) -> Vector2i:
	return _mineral_anchors[mineral]


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
	return deposit_on(x, y, terrain_at(x, y), cliff_at(x, y))


## 지형 · 절벽을 이미 알 때 — 섬 전체를 만들 때 지형 계산을 두 번 하지 않는다.
## 칸마다 해시값 하나: 그 칸 규칙의 채울 몫 안이면 누적 몫으로 종류를 고른다. 그래서 지형마다 센 비가 설정대로 나온다.
func deposit_on(x: int, y: int, kind: Terrain, cliff: bool) -> Deposit:
	var cell := Vector2i(x, y)
	if kind == Terrain.SEA or in_spawn_clear(cell):
		return Deposit.NONE
	if not cliff:
		var starter := starter_deposit(cell)
		if starter != Deposit.NONE:
			return starter
		for mineral in _mineral_anchors:
			if _mineral_anchors[mineral] == cell and kind == IslandConfig.MINERAL_TERRAIN[mineral]:
				return mineral
	var rule: Array = _rules[CLIFF_KEY if cliff else kind]
	var r := hash01(world_seed, x, y, SALT_DEPOSIT)
	if r >= rule[0]:
		return Deposit.NONE
	r /= rule[0]
	var picks: Array = rule[1]
	for pick in picks:
		if r < pick[1]:
			return pick[0]
	return picks[picks.size() - 1][0]


## 빈손 시작 보장 덩이 — 스폰 동쪽은 나무, 서쪽은 돌. 덩이 밖이면 NONE.
func starter_deposit(cell: Vector2i) -> Deposit:
	var d := cell - config.spawn()
	var near := config.spawn_clear / 2 + 2
	var patch := config.starter_patch
	if absi(d.y) > patch.y / 2 or absi(d.x) < near or absi(d.x) >= near + patch.x:
		return Deposit.NONE
	return Deposit.TREE if d.x > 0 else Deposit.STONE


func in_spawn_clear(cell: Vector2i) -> bool:
	var half := config.spawn_clear / 2
	var d := (cell - config.spawn()).abs()
	return d.x <= half and d.y <= half


static func _compile(rule: DepositRule, allowed: Array) -> Array:
	var picks := []
	var sum := 0.0
	for share in rule.shares(allowed):
		sum += share[1]
		picks.append([share[0], sum])
	return [rule.fill() if not picks.is_empty() else 0.0, picks]


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
