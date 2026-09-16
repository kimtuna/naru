class_name HarvestConfig
extends Resource
## 채취(벌목 · 채광 · 맨손) 규칙과 수치 — 한 곳에 모은다 (값은 life/harvest/harvest_config.tres).
## spec/04_life/logging.md · mining.md · gathering.md: 도끼 → 나무, 곡괭이 → 돌 · 광물, 맨손 → 나무 · 돌을 느리게.
## 내구도 · 드롭 수량 · 도달 거리는 spec 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://life/harvest/harvest_config.tres"
const Deposit := IslandConfig.Deposit

## 손에 든 아이템 id. 빈손은 HAND.
const HAND := &""
const AXE := &"axe"
const PICKAXE := &"pickaxe"

## 손에 든 것 → 칠 수 있는 자원. 여기 없는 조합은 아무 일도 없다.
const TARGETS := {
	HAND: [Deposit.TREE, Deposit.STONE],
	AXE: [Deposit.TREE],
	PICKAXE: [Deposit.STONE, Deposit.ORE],
}

## 자원 → 떨어지는 아이템 id.
const DROPS := {
	Deposit.TREE: "wood",
	Deposit.STONE: "stone",
	Deposit.ORE: "ore",
}

## 손이 닿는 거리 — 캐릭터 한가운데에서 칸 한가운데까지 (타일 수).
@export var reach_tiles := 2.0
## 좌클릭을 쥐고 있으면 이 간격(초)마다 한 번씩 휘두른다.
@export var swing_interval := 0.35
## 자원을 없애려면 쌓아야 하는 힘.
@export var deposit_hp := 3
## 한 번 휘두를 때 쌓는 힘 — 맞는 도구는 한 번에, 맨손은 여러 번.
@export var tool_power := 3
@export var hand_power := 1
## 없앤 자원 하나에서 떨어지는 수.
@export var drop_count := 1


static func load_default() -> HarvestConfig:
	return load(DEFAULT_PATH) as HarvestConfig


## 아이템(핫바 칸 값)에서 도구 id. 빈손이면 HAND.
static func tool_of(item: Variant) -> StringName:
	if item is Dictionary:
		return StringName(str(item.get("id", "")))
	return HAND


static func can_harvest(tool: StringName, deposit: Deposit) -> bool:
	return deposit in TARGETS.get(tool, [])


func power_of(tool: StringName) -> int:
	return hand_power if tool == HAND else tool_power


func reach_px(tile_px: int) -> float:
	return reach_tiles * tile_px
