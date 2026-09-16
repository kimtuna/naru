class_name WorldSettings
extends RefCounted
## 월드 설정 — 서버장만 바꾼다. 게임 도중에도 바꿀 수 있고, 월드 저장에 붙는다 (spec/01_settings/world-settings.md).
## 바꾸는 쪽이 서버장인지 함께 넘긴다 — 아니면 거부하고 값은 그대로다.

## 무엇이 바뀌었나 — 항목 이름(DEATH_PENALTY 등)과 새 값. 게임이 듣고 바로 적용한다.
signal changed(key: StringName, value: Variant)

const DEATH_PENALTY := &"death_penalty"
## 기본값 — 데스 페널티 켬 (사람 결정 2026-09-16).
const DEFAULT_DEATH_PENALTY := true

## 데스 페널티 — 켜져 있으면 죽은 자리에 상자가 떨어진다 (spec/08_combat/damage-death.md).
var death_penalty := DEFAULT_DEATH_PENALTY


## 데스 페널티를 바꾼다. 서버장이 아니면 거부하고 false.
func set_death_penalty(on: bool, by_host: bool) -> bool:
	if not by_host:
		return false
	if death_penalty != on:
		death_penalty = on
		changed.emit(DEATH_PENALTY, on)
	return true


func to_dict() -> Dictionary:
	return {String(DEATH_PENALTY): death_penalty}


## 저장에서 읽는다. 없거나 틀린 값은 기본값.
static func from_dict(d: Variant) -> WorldSettings:
	var s := WorldSettings.new()
	if d is Dictionary and d.get(String(DEATH_PENALTY)) is bool:
		s.death_penalty = d[String(DEATH_PENALTY)]
	return s
