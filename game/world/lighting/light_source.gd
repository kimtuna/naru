class_name LightSource
extends Node2D
## 광원 하나 (램프 자리) — 둘레 radius 픽셀만 밝힌다.
## 어둠(CanvasModulate)은 그대로 두고 그 위에 더한다 — 가운데서 1, 가장자리에서 0 으로 줄고 반경 밖은 0.

## 반경 (월드 픽셀).
var radius := 96.0
var _light: PointLight2D
var _image: Image


static func create(pos: Vector2, light_radius: float) -> LightSource:
	var source := LightSource.new()
	source.position = pos
	source.radius = light_radius
	return source


func _init() -> void:
	_light = PointLight2D.new()
	_light.name = "Light"
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.energy = 0.0
	add_child(_light)


func _ready() -> void:
	_image = _make_image(radius)
	_light.texture = ImageTexture.create_from_image(_image)


func light() -> PointLight2D:
	return _light


## 어둠 위에 더할 세기 — Lighting 이 밤 밝기에 맞춰 준다.
func set_strength(value: float) -> void:
	_light.energy = value


func strength() -> float:
	return _light.energy


## 이 광원이 pos 에 더하는 밝기. 그림(_make_image)과 같은 선형 감쇠다.
func contribution_at(pos: Vector2) -> float:
	var d := global_position.distance_to(pos)
	if d >= radius:
		return 0.0
	return _light.energy * (1.0 - d / radius)


## 광원 그림 — 지름 = 2 × 반경. 가운데 흰색에서 반경까지 선형으로 검정, 반경 밖(모서리)은 검정이라 더하는 것이 없다.
## CPU 에서 만든다 — 그린 그대로를 테스트가 읽을 수 있다 (헤드리스는 GPU 텍스처를 못 읽는다).
func image() -> Image:
	return _image


static func _make_image(r: float) -> Image:
	var size := maxi(2, ceili(r * 2.0))
	var img := Image.create(size, size, false, Image.FORMAT_L8)
	var center := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var d := (Vector2(x, y) + Vector2(0.5, 0.5)).distance_to(center)
			var v := clampf(1.0 - d / r, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return img
