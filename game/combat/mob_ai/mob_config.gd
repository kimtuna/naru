class_name MobConfig
extends Resource
## 시험용 몹의 AI 수치 — 한 곳에 모은다 (값은 combat/mob_ai/mob_config.tres).
## spec/08_combat/mob-ai.md: 몹 목록 · AI 행동 패턴은 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.
## 거리는 픽셀, 시간은 초. 체력은 DamageConfig.mob_max_health.

const DEFAULT_PATH := "res://combat/mob_ai/mob_config.tres"

## 이 거리 안에 들어온 플레이어를 발견한다.
@export var sight_radius := 96.0
## 쫓던 대상이 이 거리보다 멀어지면 놓친다 (발견 거리보다 넓어야 경계에서 떨지 않는다).
@export var lose_radius := 144.0
## 쫓는 속력 (초당 픽셀). 플레이어(80)보다 느려 도망칠 수 있다.
@export var move_speed := 50.0
## 대상 한가운데까지 이 거리 안이면 멈춰 공격한다. 몸끼리 닿는 거리(12)보다 넓어야 한다.
@export var attack_range := 16.0
## 한 번 때릴 때의 피해.
@export var attack_damage := 5.0
## 공격 사이 간격.
@export var attack_interval := 1.0
## 떼로 부를 때 몹 사이 간격 — 한 자리에 여러 마리를 부르면 이 간격으로 둘레에 늘어선다.
@export var spawn_spacing := 16.0


static func load_default() -> MobConfig:
	return load(DEFAULT_PATH) as MobConfig
