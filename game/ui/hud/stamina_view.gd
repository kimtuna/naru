class_name StaminaView
extends Control
## 기력 표시 — 캐릭터 바로 아래 막대. 절벽에 있거나 기력이 덜 찼을 때만 보인다 (spec/04_life/climbing.md).
## 남은 양에 따라 초록 → 주황 → 빨강 (경계는 ClimbingConfig). 색은 임시다 — 아트는 사람이 나중에 넣는다.

const ZONE_COLORS := {
	Stamina.Zone.GREEN: Color(0.3, 0.8, 0.3),
	Stamina.Zone.ORANGE: Color(0.95, 0.6, 0.15),
	Stamina.Zone.RED: Color(0.9, 0.2, 0.2),
}

var climber: Climber


func bind(target: Climber) -> void:
	climber = target
	refresh()


func _process(_delta: float) -> void:
	refresh()


func refresh() -> void:
	visible = climber != null and climber.shows_stamina()
	if climber == null:
		return
	var s := climber.stamina
	%Fill.size.x = size.x * clampf(s.fraction(), 0.0, 1.0)
	%Fill.color = ZONE_COLORS[s.zone()]


func fill_ratio() -> float:
	return %Fill.size.x / size.x if size.x > 0.0 else 0.0


func fill_color() -> Color:
	return %Fill.color
