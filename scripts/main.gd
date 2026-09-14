extends Node2D

## 화면 뼈대 + 월드 + 플레이어.
## 「숫자가 옳은지는 화면을 봐야 안다」 — 그 화면을 띄우는 자리다.
##
## **카메라가 플레이어를 따라간다** (P1-6). 카메라는 플레이어 씬 안에 있다 —
## 코드가 매 프레임 따라 붙이는 것이 아니라 **부모-자식이라 공짜로 따라간다.**
## 그래서 바퀴 7 의 `tile_offset` 이 사라졌다: 플레이어는 스폰 칸(128,128)의
## 한가운데에 그냥 서 있고 카메라가 거기를 비춘다. **화면 칸 = 월드 칸**이다.
##
## **줌은 1 이다** (BACKLOG P1): 줌이 곧 시야라서, 1 이 아니면 창이 큰 사람이 더 멀리 본다.
##
## **임시 격자를 걷어냈다.** 이제 화면에 있는 것은 진짜 월드다 — 같은 씨앗이 만든
## 그 섬이고, 파랗게 보이는 칸이 곧 못 들어가는 칸이다. 색은 `WorldView` 가 정한다.
##
## **보이는 칸만 그린다.** 그릴 범위는 `visible_world_rect()` 가 준다 —
## 카메라의 위치·줌이 전부 그 안에 들어 있다.

## 이 판의 씨앗. 저장·불러오기가 생기면 세이브에서 온다 (GDD D-1).
const WORLD_SEED := 20260914

@onready var _player: Player = $Player

## 지난 프레임에 실제로 그린 칸 수. **`measure_draw.gd` 가 이 수를 읽는다** —
## 월드를 통째로 그려도 화면 픽셀은 똑같아서 그림만 봐서는 못 잡는다.
var drawn_tiles := 0

## 색을 다시 채운 횟수. 같은 이유로 밖에 낸다 — 캐시는 눈에 안 보인다.
var cache_fills := 0

## **색은 프레임마다 다시 계산하지 않는다.** 한 칸이 6.71 µs (잡음을 두 번 돈다) 라
## 273칸이면 1.83 ms — 60Hz 한 프레임 예산의 11% 다 (NUMBERS 9절). 나무도 몹도 UI 도
## 아직 없는데 그걸 쓸 수는 없다.
##
## **칸이 바뀌는 게 아니라 보이는 범위가 바뀔 때만** 다시 채운다. 240 px/s 로 걸으면
## 한 축당 초당 5번이므로 평균 비용이 20배 내려간다.
## 대가는 **상해도 눈에 안 보이는 것**이다 — 그래서 measure_draw.gd 가 걸은 뒤에
## 픽셀을 한 번 더 맞춰 본다.
var _cache_range := Rect2i()
var _cache := PackedColorArray()

func _ready() -> void:
	_link_world()
	var vis := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	print("VIEWPORT %d x %d" % [int(vis.x), int(vis.y)])
	print("WINDOW   %d x %d" % [win.x, win.y])
	print("SCALE    %.2f x" % (float(win.x) / vis.x))
	print("TILE     %d px · 보이는 칸 %.2f x %.2f" % [
		int(PlayerMotion.TILE), vis.x / PlayerMotion.TILE, vis.y / PlayerMotion.TILE])
	print("SPEED    %d px/s = %.1f 칸/s" % [
		int(PlayerMotion.SPEED), PlayerMotion.SPEED / PlayerMotion.TILE])
	print("WORLD    씨앗 %d · %dx%d 칸 · 스폰 %s · 시작 %s" % [
		WORLD_SEED, WorldGen.SIZE, WorldGen.SIZE, WorldGen.spawn_tile(), _player.position])
	print("CAM      줌 %s · 보이는 월드 %s" % [
		get_viewport().get_canvas_transform().get_scale(), visible_world_rect()])
	print("RANGE    보이는 칸 %d / 월드 %d 칸" % [
		WorldView.tile_count(visible_world_rect()), WorldGen.SIZE * WorldGen.SIZE])

## 플레이어를 월드에 꽂는다. **이 줄이 없으면 바다 위를 걸어다닌다.**
func _link_world() -> void:
	_player.solid = WorldCollide.solid_from_seed(WORLD_SEED)

## 카메라가 움직이면 보이는 월드 범위가 달라진다 — 타일은 월드에 고정돼 있으므로
## 다시 그려야 한다.
func _process(_delta: float) -> void:
	queue_redraw()

## 지금 화면에 걸리는 월드 범위(픽셀). 카메라의 위치·줌이 전부 여기 들어 있다.
func visible_world_rect() -> Rect2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)

func _draw() -> void:
	var t := PlayerMotion.TILE
	var r := WorldView.tile_range(visible_world_rect())
	if r != _cache_range:
		_fill_cache(r)
	var i := 0
	for ty in range(r.position.y, r.position.y + r.size.y):
		for tx in range(r.position.x, r.position.x + r.size.x):
			draw_rect(Rect2(tx * t, ty * t, t, t), _cache[i])
			i += 1
	drawn_tiles = i

func _fill_cache(r: Rect2i) -> void:
	_cache.resize(r.size.x * r.size.y)
	var i := 0
	for ty in range(r.position.y, r.position.y + r.size.y):
		for tx in range(r.position.x, r.position.x + r.size.x):
			_cache[i] = WorldView.color_at(WORLD_SEED, tx, ty)
			i += 1
	_cache_range = r
	cache_fills += 1
