class_name HarvestConfig
extends Resource
## 채취(벌목 · 채광) 규칙과 수치 — 한 곳에 모은다 (값은 life/harvest/harvest_config.tres).
## spec/04_life/logging.md · mining.md: 좌클릭 평타로 치면 채취가 진행된다.
## 맞는 도구(도끼 → 나무, 곡괭이 → 돌 · 광물)는 빠르고, 맞지 않는 도구 · 맨손은 느리다.
## 광물은 곡괭이가 있어야 캐진다 — 임시 규칙 (spec: 곡괭이 등급별 채굴 가능 대상 미정).
## 내구도 · 드롭 수량은 spec 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.
## 휘두르는 간격 · 손이 닿는 거리는 평타 수치(SwingConfig)에 있다.

const DEFAULT_PATH := "res://life/harvest/harvest_config.tres"
const Deposit := IslandConfig.Deposit

## 손에 든 아이템 id. 빈손은 HAND.
const HAND := &""
const AXE := &"axe"
const PICKAXE := &"pickaxe"

## 자원 → 빨리 캐는 도구.
const RIGHT_TOOLS := {
	Deposit.TREE: [AXE],
	Deposit.STONE: [PICKAXE],
	Deposit.ORE: [PICKAXE],
}

## 자원 → 이것을 들어야만 캐진다. 여기 없는 자원은 무엇으로든(맨손 포함) 캐진다.
const REQUIRED_TOOLS := {
	Deposit.ORE: [PICKAXE],
}

## 자원 → 떨어지는 아이템 id.
const DROPS := {
	Deposit.TREE: "wood",
	Deposit.STONE: "stone",
	Deposit.ORE: "ore",
}

## 자원을 없애려면 쌓아야 하는 힘.
@export var deposit_hp := 3
## 한 번 칠 때 쌓는 힘 — 맞는 도구는 한 번에.
@export var tool_power := 3
## 맞지 않는 도구 · 맨손은 여러 번.
@export var slow_power := 1
## 없앤 자원 하나에서 떨어지는 수.
@export var drop_count := 1


static func load_default() -> HarvestConfig:
	return load(DEFAULT_PATH) as HarvestConfig


## 아이템(핫바 칸 값)에서 도구 id. 빈손이면 HAND.
static func tool_of(item: Variant) -> StringName:
	if item is Dictionary:
		return StringName(str(item.get("id", "")))
	return HAND


## 이 도구로 이 자원을 캘 수 있나 (빠르기와 상관없이).
static func can_harvest(tool: StringName, deposit: Deposit) -> bool:
	return DROPS.has(deposit) and (not REQUIRED_TOOLS.has(deposit) or tool in REQUIRED_TOOLS[deposit])


static func is_right_tool(tool: StringName, deposit: Deposit) -> bool:
	return tool in RIGHT_TOOLS.get(deposit, [])


## 이 도구로 캘 수 있는 자원 전부.
static func harvestable_by(tool: StringName) -> Array:
	return DROPS.keys().filter(func(d): return can_harvest(tool, d))


func power_of(tool: StringName, deposit: Deposit) -> int:
	return tool_power if is_right_tool(tool, deposit) else slow_power
