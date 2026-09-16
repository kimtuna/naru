class_name DepositRule
extends Resource
## 지형 하나의 자원 비율 규칙 — 「채울 %」 하나 + 종류 사이의 비 (spec/03_world/island-generation.md · terrain.md).
## 칸마다 해시값 하나로 정한다: 값이 채울 % 안이면 비대로 종류를 고른다.
## 그 지형에 못 나는 종류(IslandConfig.allowed_deposits)의 비는 0 으로 본다.

const Deposit := IslandConfig.Deposit

## 이 지형 칸의 몇 %를 자원으로 채우나 (0 ~ 100).
@export_range(0.0, 100.0) var fill_percent := 30.0
## 종류 사이의 비.
@export var tree_weight := 0.0
@export var stone_weight := 0.0
@export var iron_weight := 0.0
@export var sulfur_weight := 0.0
@export var herb_weight := 0.0


static func create(fill: float, weights: Dictionary) -> DepositRule:
	var rule := DepositRule.new()
	rule.fill_percent = fill
	for kind in weights:
		rule.set_weight(kind, weights[kind])
	return rule


func fill() -> float:
	return clampf(fill_percent / 100.0, 0.0, 1.0)


func weight(kind: Deposit) -> float:
	match kind:
		Deposit.TREE:
			return maxf(tree_weight, 0.0)
		Deposit.STONE:
			return maxf(stone_weight, 0.0)
		Deposit.IRON:
			return maxf(iron_weight, 0.0)
		Deposit.SULFUR:
			return maxf(sulfur_weight, 0.0)
		Deposit.HERB:
			return maxf(herb_weight, 0.0)
	return 0.0


func set_weight(kind: Deposit, value: float) -> void:
	match kind:
		Deposit.TREE:
			tree_weight = value
		Deposit.STONE:
			stone_weight = value
		Deposit.IRON:
			iron_weight = value
		Deposit.SULFUR:
			sulfur_weight = value
		Deposit.HERB:
			herb_weight = value


## allowed 안의 종류만 센 비 — [[종류, 채운 칸 가운데 몫]]. 비가 모두 0 이면 빈 배열.
func shares(allowed: Array) -> Array:
	var total := 0.0
	for kind in allowed:
		total += weight(kind)
	var out := []
	if total <= 0.0:
		return out
	for kind in allowed:
		if weight(kind) > 0.0:
			out.append([kind, weight(kind) / total])
	return out
