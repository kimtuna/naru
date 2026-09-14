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
##
## **좌클릭은 손에 든 것으로 간다** (GDD D-2c): 무엇을 하는지는 「무엇을 눌렀나」가
## 아니라 「무엇을 겨눴나」가 정하므로 버튼은 하나다. 여기서는 **손에 든 것의 색을
## 플레이어에게 넘기는 것**까지만 한다 — 맞힐 것이 아직 월드에 없다.
##
## **핫바는 화면에 못 박혀 있다** (GDD D-2c): `UI` 는 `CanvasLayer` 라 카메라를 안 탄다.
## 숫자키를 읽어 손을 옮기는 것도 여기서 한다 — `Hotbar` 는 순수 계산이라
## 엔진 입력을 안 본다.

## 좌클릭의 입력 액션 이름. project.godot 의 글자와 **한 곳에서** 만난다.
const USE_ACTION := &"use"

## 이 판의 씨앗. 저장·불러오기가 생기면 세이브에서 온다 (GDD D-1).
const WORLD_SEED := 20260914

@onready var _player: Player = $Player
@onready var _hotbar_view: HotbarView = $UI/Hotbar

## 손. 화면 아래 9칸 + 지금 든 칸 (GDD D-2c).
var hotbar := Hotbar.new()

## 숫자키의 **직전 프레임 상태**. 눌린 순간에만 손이 움직인다.
## **`is_action_just_pressed` 를 안 쓴다**: 「눌린 프레임」이 딱 한 번뿐이라
## `_process` 가 그 프레임을 비껴가면 아무 일도 안 일어난다 — 실측 게이트는
## `Input.action_press` 로 키를 몇 프레임 눌러 두므로 그 창에 걸린다.
var _key_down := PackedByteArray()

## 지난 프레임에 실제로 그린 칸 수. **`measure_window.gd` 의 DRAW 가 이 수를 읽는다** —
## 월드를 통째로 그려도 화면 픽셀은 똑같아서 그림만 봐서는 못 잡는다.
var drawn_tiles := 0

## 색을 다시 채운 횟수. 같은 이유로 밖에 낸다 — 캐시는 눈에 안 보인다.
var cache_fills := 0

## 마지막으로 색을 채우는 데 걸린 시간(µs). **한 프레임 예산 16667 µs 와 견주는 값이다.**
var fill_usec := 0

## **색은 프레임마다 다시 계산하지 않는다.** 한 칸이 6.71 µs (잡음을 두 번 돈다) 라
## 한 화면이면 밀리초 단위다 (NUMBERS 9절). 타일이 32 → 16 으로 작아지면서 한 화면의
## 칸이 558 → 2135 로 **3.8배 늘었다** — 한 판의 비용도 그만큼이다.
## **그래서 채우는 데 걸린 시간을 재서 밖에 낸다** (`fill_usec`) — 사람 눈에는
## 「걸을 때 가끔 끊긴다」로만 보이는 값이라 숫자로 안 내면 아무도 못 본다.
##
## **칸이 바뀌는 게 아니라 보이는 범위가 바뀔 때만** 다시 채운다. 240 px/s 로 걸으면
## 한 축당 초당 15번이므로 평균 비용이 4배 내려간다.
## 대가는 **상해도 눈에 안 보이는 것**이다. 캐시를 안 버리면 화면이 월드에서 미끄러지는데,
## measure_window.gd 의 DRAW 가 구운 픽셀을 월드 칸과 맞춰서 최대 색차 86.0/255 로 잡는다.
var _cache_range := Rect2i()
var _cache := PackedColorArray()

func _ready() -> void:
	_link_world()
	_key_down.resize(Hotbar.SLOTS)
	_hotbar_view.hotbar = hotbar
	_hotbar_view.queue_redraw()
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
	_poll_hotbar()
	_poll_use()
	queue_redraw()

## 숫자키 1..9 → 손. 액션 이름은 `Hotbar` 가 만든다 — 여기서 글자를 다시 적으면
## project.godot 의 배선과 갈라진다.
func _poll_hotbar() -> void:
	for i in Hotbar.SLOTS:
		var down: int = 1 if Input.is_action_pressed(Hotbar.action_for(i)) else 0
		if down == 1 and _key_down[i] == 0:
			hotbar.select(i)
			_hotbar_view.queue_redraw()
		_key_down[i] = down

## 좌클릭 → 손에 든 것의 동작. **누르고 있으면 계속 휘두른다** (HandSwing 머리말)
## 이라서 「눌린 순간」을 따로 안 잡는다 — 겹치지 않게 막는 것은 `HandSwing.start()` 다.
## 숫자키가 직전 프레임을 들고 있어야 했던 것과 다른 자리다: 저쪽은 **한 번**이고
## 이쪽은 **누르는 동안 내내**다.
func _poll_use() -> void:
	if Input.is_action_pressed(USE_ACTION):
		_player.use(HandSwing.color_for(hotbar.held_id()))

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
	var t0 := Time.get_ticks_usec()
	_cache.resize(r.size.x * r.size.y)
	var i := 0
	for ty in range(r.position.y, r.position.y + r.size.y):
		for tx in range(r.position.x, r.position.x + r.size.x):
			_cache[i] = WorldView.color_at(WORLD_SEED, tx, ty)
			i += 1
	_cache_range = r
	cache_fills += 1
	fill_usec = Time.get_ticks_usec() - t0
