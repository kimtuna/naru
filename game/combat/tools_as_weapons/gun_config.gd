class_name GunConfig
extends Resource
## 총 수치 — 총마다 피해 · 탄속 · 사거리 · 연사 간격, 탄약 (값은 combat/tools_as_weapons/gun_config.tres).
## spec/08_combat/tools-as-weapons.md: 총 종류 · 탄약 종류는 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://combat/tools_as_weapons/gun_config.tres"

## 총 아이템 id → {"damage": 피해, "speed": 탄속(픽셀/초), "range": 사거리(픽셀), "interval": 연사 간격(초)}.
@export var guns := {"gun": {"damage": 5.0, "speed": 240.0, "range": 160.0, "interval": 0.4}}
## 한 발에 쓰는 탄약 아이템 id 와 개수.
@export var ammo_id := "ammo"
@export var ammo_per_shot := 1
## 투사체가 몹에 맞는 거리 — 투사체가 지나간 선이 몹 한가운데에서 이만큼 안이면 맞는다 (픽셀).
@export var hit_radius := 7.0
## 투사체가 쏜 자리에서 몸 앞으로 나와 시작하는 거리 (픽셀).
@export var muzzle_offset := 6.0


static func load_default() -> GunConfig:
	return load(DEFAULT_PATH) as GunConfig


## 이 아이템(핫바 칸 값, 빈손이면 null)이 총인가.
func is_gun(item: Variant) -> bool:
	return item is Dictionary and guns.has(str(item.get("id", "")))


## 총의 수치 하나. 총이 아니면 0.
func stat(item: Variant, key: String) -> float:
	if not is_gun(item):
		return 0.0
	return float(guns[str(item.get("id", ""))].get(key, 0.0))
