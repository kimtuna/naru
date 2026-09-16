class_name Lighting
extends Node2D
## 화면 밝기 — 밤이면 월드를 어둡게 하고(CanvasModulate), 광원이 제 반경만 되돌린다.
## spec/03_world/lighting.md: 밝히는 것은 반경이지 화면이 아니다. HUD(CanvasLayer)는 어두워지지 않는다.

## 비워 두면 lighting_config.tres 를 쓴다.
@export var config: LightingConfig

var clock: WorldClock
var _dark: CanvasModulate
var _lights: Node2D


func _init() -> void:
	_dark = CanvasModulate.new()
	_dark.name = "Dark"
	add_child(_dark)
	_lights = Node2D.new()
	_lights.name = "Lights"
	add_child(_lights)


func _ready() -> void:
	if config == null:
		config = LightingConfig.load_default()
	refresh()


func setup(world_clock: WorldClock) -> void:
	clock = world_clock
	clock.night_changed.connect(func(_night: bool) -> void: refresh())
	refresh()


func is_night() -> bool:
	return clock != null and clock.is_night()


## 광원이 없는 곳의 밝기 — 낮/밤 값 그대로.
func ambient() -> float:
	return config.night_brightness if is_night() else config.day_brightness


## 월드 위치 pos 의 밝기 (0~1). 광원 반경 밖이면 ambient() 와 같다.
func brightness_at(pos: Vector2) -> float:
	var value := ambient()
	for source in lights():
		value += source.contribution_at(pos)
	return minf(value, 1.0)


func darkness() -> CanvasModulate:
	return _dark


## 광원(램프 자리)을 pos 에 둔다. radius 를 안 주면 설정의 램프 반경.
func add_light(pos: Vector2, radius := -1.0) -> LightSource:
	var source := LightSource.create(pos, config.lamp_radius if radius < 0.0 else radius)
	_lights.add_child(source)
	source.set_strength(_light_strength())
	return source


func lights() -> Array[LightSource]:
	var out: Array[LightSource] = []
	for child in _lights.get_children():
		if child is LightSource and not child.is_queued_for_deletion():
			out.append(child)
	return out


## 낮/밤이 바뀌었을 때 어둠과 광원 세기를 다시 맞춘다.
func refresh() -> void:
	if config == null:
		return
	var b := ambient()
	_dark.color = Color(b, b, b)
	for source in lights():
		source.set_strength(_light_strength())


## 광원 가운데가 딱 원래 밝기(1)로 돌아오는 세기 — 낮에는 0 이라 밝은 화면을 더 밝히지 않는다.
func _light_strength() -> float:
	return 1.0 - ambient()
