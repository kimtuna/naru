class_name WeaponConfig
extends Resource
## 근접 공격 수치 — 손에 든 것마다 한 번 칠 때 주는 피해 (값은 combat/tools_as_weapons/weapon_config.tres).
## spec/08_combat/tools-as-weapons.md: 도구가 곧 근접 무기다. 도구별 공격 스탯은 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.
## 표에 없는 아이템(나무 · 돌 같은 재료)은 other_attack, 빈손은 hand_attack.

const DEFAULT_PATH := "res://combat/tools_as_weapons/weapon_config.tres"

## 빈손으로 칠 때의 피해.
@export var hand_attack := 2.0
## 아이템 id → 피해. 도구가 여기 들어간다.
@export var attacks := {"axe": 8.0, "pickaxe": 6.0}
## 표에 없는 아이템을 들고 칠 때의 피해.
@export var other_attack := 1.0
## 몹이 맞는 둘레 반지름 (픽셀) — 휘두른 선이 이만큼 안을 지나면 앞의 것으로 본다.
@export var mob_radius := 6.0


static func load_default() -> WeaponConfig:
	return load(DEFAULT_PATH) as WeaponConfig


## 손에 든 것(핫바 칸 값, 빈손이면 null)으로 한 번 칠 때의 피해.
func attack_of(item: Variant) -> float:
	if not item is Dictionary:
		return hand_attack
	return float(attacks.get(str(item.get("id", "")), other_attack))
