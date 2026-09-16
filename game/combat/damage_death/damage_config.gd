class_name DamageConfig
extends Resource
## 체력 수치 — 한 곳에 모은다 (값은 combat/damage_death/damage_config.tres).
## spec/08_combat/damage-death.md: 체력 수치는 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://combat/damage_death/damage_config.tres"

## 캐릭터 최대 체력. 다시 시작하면 이만큼 채워진다.
@export var player_max_health := 100.0
## 몹 최대 체력 (몹 종류가 생기기 전 기본값).
@export var mob_max_health := 30.0
## 데스 상자가 사라지기까지 (초). 30분 (사람 결정 2026-09-16).
## 임시로 월드가 돌아가는 동안의 실제 시간이다 — 게임 시간인지, 꺼진 동안에도 주는지는 사람 확인 전.
@export var death_chest_seconds := 1800.0


static func load_default() -> DamageConfig:
	return load(DEFAULT_PATH) as DamageConfig
