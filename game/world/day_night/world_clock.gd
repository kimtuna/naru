class_name WorldClock
extends Node
## 월드 시계 — 게임 시간을 흘리고, 날짜와 낮/밤을 알려 준다.
## 시간은 섬(IslandMap.time)에 하나만 둔다 — 재생 주기와 같은 시계를 쓰고, 저장은 WorldData.world_time.
## 날짜 · 시각 · 낮/밤은 그 시간에서 계산한다 — 따로 저장하면 서로 어긋날 수 있다.

## 날짜가 넘어갔다 (day 는 1부터).
signal day_changed(day: int)
## 낮/밤이 바뀌었다.
signal night_changed(night: bool)

## 비워 두면 day_night_config.tres 를 쓴다.
@export var config: DayNightConfig
## 시간 배속 — 테스트는 크게 올려 빨리 돌린다. 0 이면 멈춘다.
@export var speed := 1.0

## 시간을 담는 섬. 없으면 시계가 스스로 든다.
var map: IslandMap
var _own_time := 0.0
var _last_day := 1
var _last_night := false


func _ready() -> void:
	if config == null:
		config = DayNightConfig.load_default()
	_sync()


func setup(island: IslandMap) -> void:
	map = island
	_sync()


## 월드에서 흐른 게임 시간 (초).
var time: float:
	get:
		return map.time if map else _own_time
	set(value):
		if map:
			map.time = value
		else:
			_own_time = value


func _process(delta: float) -> void:
	advance(delta * speed)


## 게임 시간을 seconds 흘린다. 넘어간 날짜 · 낮밤 경계마다 신호를 낸다 — 한 번에 며칠을 넘겨도 빠뜨리지 않는다.
func advance(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var target := time + seconds
	while true:
		var edge := _next_edge(time)
		if edge > target:
			break
		time = edge
		_emit_changes()
	time = target
	_emit_changes()


## 날짜 — 첫날이 1.
func day() -> int:
	return int(floor(time / config.day_seconds)) + 1


## 오늘 하루 안에서 흐른 초 (0 이상 day_seconds 미만).
func time_of_day() -> float:
	return fposmod(time, config.day_seconds)


func is_night() -> bool:
	return time_of_day() >= config.daytime_seconds


## at 뒤의 첫 경계(해 질 녘 또는 자정) 시각.
func _next_edge(at: float) -> float:
	var start: float = floor(at / config.day_seconds) * config.day_seconds
	for edge: float in [start + config.daytime_seconds, start + config.day_seconds, start + config.day_seconds + config.daytime_seconds]:
		# 소수 오차로 start 가 하루 늦게 잡혀도 제자리 경계를 다시 돌지 않는다.
		if edge > at:
			return edge
	return start + 2.0 * config.day_seconds


func _emit_changes() -> void:
	var d := day()
	var n := is_night()
	if d != _last_day:
		_last_day = d
		day_changed.emit(d)
	if n != _last_night:
		_last_night = n
		night_changed.emit(n)


## 시간을 바깥에서 바꿨을 때(불러오기) 신호 없이 기준만 맞춘다.
func _sync() -> void:
	if config == null:
		return
	_last_day = day()
	_last_night = is_night()
