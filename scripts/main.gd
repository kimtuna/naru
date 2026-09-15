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
## **나무·돌·광물도 그 색 안에 있다** (회차 24): 오브젝트를 따로 그리는 코드가 여기
## 한 줄도 없다 — `WorldView.color_at` 이 그 칸을 제 색으로 준다. 그래서 「놓았는데
## 화면에 없다」가 구운 픽셀에서 빨개진다.
##
## **보이는 칸만 그린다.** 그릴 범위는 `visible_world_rect()` 가 준다 —
## 카메라의 위치·줌이 전부 그 안에 들어 있다.
##
## **좌클릭은 손에 든 것으로 간다** (GDD D-2c): 무엇을 하는지는 「무엇을 눌렀나」가
## 아니라 「무엇을 겨눴나」가 정하므로 버튼은 하나다. 모션은 `Player` 가, **판정은
## `Harvest` 가** 한다 — 여기는 둘을 잇는 한 줄이다 (회차 29 벌목).
##
## **월드의 바뀐 것은 `WorldState` 가 들고 있다.** 배치는 씨앗에서 나오는 순수 함수라
## 상태가 없어서, 벤 칸도 바닥에 떨어진 것도 적을 자리가 없었다 (회차 24 가 남긴 물음).
## 그리는 쪽·막는 쪽이 **둘 다 그 하나**를 본다: 나무를 베면 화면에서 사라지고 그 자리로
## 걸어 들어갈 수 있다 — 한쪽만 고쳐지면 「벤 자리에 몸이 낀다」가 된다.
##
## **시간이 흐른다** (회차 30): `_process` 가 `world.tick(delta)` 를 부르고, 때가 된
## 벤 칸은 나무로 돌아온다 (GDD A-4 「한 번 캐고 끝나는 자원이 없다」).
## **몸이 서 있는 칸은 안 자란다** — 월드가 플레이어를 모르므로 여기가 그 물음을 잇는다.
##
## **낮과 밤** (회차 31): 그 시계를 `DayCycle` 이 빛 하나로 바꾸고, `Sky` 가 화면에
## 곱한다 (GDD G-1b). **칸 색은 한 톨도 안 고친다** — 밤을 색 캐시에 섞으면 빛이 계속
## 변하는 만큼 캐시를 매 프레임 버려야 해서 한 화면(2135칸 · 7.9 ms)이 프레임 예산의
## 절반을 먹는다. `CanvasModulate` 는 곱 하나라 공짜다.
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

## 화면에 곱해지는 **하늘빛**. `CanvasModulate` 라 이 노드 하나가 캔버스 전부를 물들인다 —
## 칸 색에 밤을 섞지 않는 이유는 `DayCycle` 머리말에 있다 (색 캐시를 매 프레임 버리게 된다).
## `UI` 는 제 `CanvasLayer` 라 안 닿는다: **밤에도 핫바는 밝다.**
##
## **밖에서 보인다**(`_` 가 없다). `measure_day.gd` 가 「`Main/Sky` 라는 경로에 무엇이
## 있나」가 아니라 **이 게임이 실제로 물들이는 그 노드**를 집어서 캔버스를 묻는다 —
## 경로로 찾으면 노드를 옮기는 순간 게이트가 「없다」로 죽어서, 정작 **엉뚱한 캔버스에
## 있는 하늘**을 한 번도 못 본다 (회차 31 이 대조군에서 확인했다).
@onready var sky: CanvasModulate = $Sky

## 씨앗 월드 위에 얹힌 **바뀐 것** — 벤 칸 · 바닥에 떨어진 것. 저장(P2d)이 먹을 자리다.
var world := WorldState.new(WORLD_SEED)

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
## **벌목 게이트(CHOP)가 이 수를 읽는다**: 헤드리스라 픽셀을 못 읽지만, 벤 뒤에
## 이 수가 안 오르면 화면에는 나무가 그대로 남아 있다는 뜻이다.
var cache_fills := 0

## 지난 프레임에 그린 **바닥의 것**의 수. 칸과 따로 센다 — 같이 세면 「떨어진 것을
## 하나도 안 그렸다」가 2135 라는 큰 수에 묻힌다.
var drawn_drops := 0

## 마지막으로 색을 채우는 데 걸린 시간(µs). **한 프레임 예산 16667 µs 와 견주는 값이다.**
var fill_usec := 0

## **색은 프레임마다 다시 계산하지 않는다.** 한 칸이 **3.32 µs** 라 한 화면이면
## 밀리초 단위다 (NUMBERS 9절). 타일이 32 → 16 으로 작아지면서 한 화면의
## 칸이 558 → 2135 로 **3.8배 늘었다** — 한 판의 비용도 그만큼이다.
## **회차 24 에 6.71 → 3.32 µs 로 내려갔다**: 지형색이 높이와 지형을 따로 물어
## 잡음을 두 번 돌고 있었는데, `WorldGen.kind_at_height` 로 높이 한 번에서 둘 다 나온다.
## 나무·돌·광물이 그 위에 얹혔는데도 한 판이 13.0 → 7.9 ms 로 줄었다.
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
	print("DAY      하루 %.0f s (낮 %.0f + 밤 %.0f) · 시작 위상 %.2f (%s) · 여명 %.0f s" % [
		WorldState.DAY_SEC, WorldState.DAY_SEC * 0.5, WorldState.DAY_SEC * 0.5,
		DayCycle.phase(world.now), "낮" if DayCycle.is_day(world.now) else "밤",
		DayCycle.TWILIGHT * WorldState.DAY_SEC])

## 플레이어를 월드에 꽂는다. **이 줄이 없으면 바다 위를 걸어다닌다.**
##
## **Callable 을 한 번만 만든다**: `WorldState` 가 없앤 칸의 사전을 참조로 넘기므로,
## 나중에 벤 칸도 이미 꽂힌 이 Callable 이 그대로 본다.
func _link_world() -> void:
	_player.solid = world.solid()
	world.occupied = _body_covers
	world.changed.connect(_on_world_changed)

## 「이 칸에 몸이 서 있나」 — 다시 자라는 나무가 묻는다 (`WorldState.tick`).
## **월드는 플레이어를 모른다**: 여기가 둘을 잇는다. 상자 규칙은 `WorldCollide` 에
## 한 벌뿐이라 걷는 것과 자라는 것이 같은 네모를 본다.
func _body_covers(tile: Vector2i) -> bool:
	return WorldCollide.covers_tile(_player.position, tile)

## 월드의 한 칸이 바뀌었다. **색 캐시를 버린다** — 캐시는 「보이는 범위가 바뀔 때만」
## 다시 채우므로, 제자리에 선 채로 나무를 베면 **벤 자리에 나무가 그대로 남는다.**
## 빈 `Rect2i` 는 어떤 실제 범위와도 같을 수 없다(크기 0) — 그래서 버리는 표시로 쓴다.
func _on_world_changed(_tile: Vector2i) -> void:
	_cache_range = Rect2i()
	queue_redraw()

## 카메라가 움직이면 보이는 월드 범위가 달라진다 — 타일은 월드에 고정돼 있으므로
## 다시 그려야 한다.
func _process(delta: float) -> void:
	# **게임 시계는 여기서 흐른다.** 벤 나무가 다시 자라는 것이 이 한 줄에 달려 있다
	# (GDD A-4) — 안 부르면 `WorldState` 가 아무리 맞아도 섬은 영영 그루터기다.
	# 자란 칸은 `changed` 로 알려 오므로 색 캐시도 저절로 버려진다.
	world.tick(delta)
	# **그 시계가 화면에 나오는 자리** (GDD G-1b 하루 20분 = 낮 10 + 밤 10).
	# 빛은 매 프레임 조금씩 움직이므로 「바뀌었을 때만」이 없다 — 곱 하나라 공짜고,
	# 여기를 빼면 시계가 아무리 맞아도 **섬은 영영 한낮이다** (measure_day.gd 가 잡는다).
	sky.color = DayCycle.light_at(world.now)
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
	if not Input.is_action_pressed(USE_ACTION):
		return
	# **모션이 이번에 시작됐을 때만 판정한다.** `use()` 가 false 면 이미 휘두르는
	# 중이라, 여기서 또 판정하면 한 번의 동작이 프레임 수만큼 맞힌다 —
	# 나무 한 그루가 한 모션에 통째로 사라진다 (Harvest 머리말).
	if not _player.use(HandSwing.color_for(hotbar.held_id())):
		return
	Harvest.hit(world, hotbar.held_id(), _player.position, _player.facing)

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
	_draw_drops(visible_world_rect())

## 바닥에 떨어진 것. **칸 위에, 플레이어 아래**다 — 캐릭터가 아이템에 가리면
## 무엇을 밟고 섰는지 안 보인다 (플레이어는 자식 노드라 이 `_draw` 보다 뒤에 그려진다).
## **보이는 것만 그린다**: 목록은 판이 길어질수록 늘어나는데 화면은 그대로다.
func _draw_drops(view: Rect2) -> void:
	drawn_drops = 0
	for d in world.drops:
		var r := WorldView.drop_rect(d["pos"])
		if not view.intersects(r):
			continue
		draw_rect(r, HotbarView.item_color(d["id"]), true)
		drawn_drops += 1

func _fill_cache(r: Rect2i) -> void:
	var t0 := Time.get_ticks_usec()
	_cache.resize(r.size.x * r.size.y)
	var i := 0
	for ty in range(r.position.y, r.position.y + r.size.y):
		for tx in range(r.position.x, r.position.x + r.size.x):
			_cache[i] = WorldView.color_at(WORLD_SEED, tx, ty, world.is_cleared(tx, ty))
			i += 1
	_cache_range = r
	cache_fills += 1
	fill_usec = Time.get_ticks_usec() - t0
