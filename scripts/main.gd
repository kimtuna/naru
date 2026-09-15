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
## **사람이 차지한 칸에는 안 자란다** — 월드가 플레이어도 설치물도 모르므로 여기가
## 그 물음을 잇는다. 물음은 하나지만 **답하는 곳은 여럿**이라 목록은 `Claim` 이 든다
## (회차 32): 지금은 몸뿐이고, 제작대·밭·길이 그 뒤에 줄을 선다.
##
## **낮과 밤** (회차 31): 그 시계를 `DayCycle` 이 빛 하나로 바꾸고, `Sky` 가 화면에
## 곱한다 (GDD G-1b). **칸 색은 한 톨도 안 고친다** — 밤을 색 캐시에 섞으면 빛이 계속
## 변하는 만큼 캐시를 매 프레임 버려야 해서 한 화면(2135칸 · 7.9 ms)이 프레임 예산의
## 절반을 먹는다. `CanvasModulate` 는 곱 하나라 공짜다.
##
## **핫바는 화면에 못 박혀 있다** (GDD D-2c): `UI` 는 `CanvasLayer` 라 카메라를 안 탄다.
## 숫자키를 읽어 손을 옮기는 것도 여기서 한다 — `Hotbar` 는 순수 계산이라
## 엔진 입력을 안 본다.
##
## **가방은 `E` 로 열고 닫는다** (회차 40). 핫바와 같은 `CanvasLayer` 에 있지만
## **늘 떠 있지 않다** — 창이라 월드를 가린다.
##
## **창이 열려 있는 동안 입력이 갈린다** (회차 43): **걸을 수는 있고**(코어 키퍼 방식)
## **좌클릭은 안 휘두르고 숫자키는 손을 안 바꾼다.** 그 표는 `InputRoute` 에 있고
## 여기는 **창이 열렸나만 답한다**(`_ui_open`) — `_poll_*` 마다 조건을 적으면
## 창이 늘 때(상자 · 제작대) 어느 회차가 한 곳을 빼먹는다.
##
## **그 좌클릭이 가는 곳이 생겼다** (회차 44 · 집어서 놓기): 창이 열려 있으면 클릭은
## 커서 아래의 칸으로 간다 — 가방 18칸과 핫바 9칸을 오간다. 계산은 `Grab` 이고
## 여기는 **화면의 점 하나를 어느 칸으로 읽나**를 잇는다 (`grab_at`).
## 회차 43 의 「좌클릭은 UI 로 간다」가 이제 빈말이 아니다.

## 좌클릭 · 가방 키의 입력 액션 이름. **`InputRoute` 가 출처다** — 갈래 표와 글자가
## 같은 곳에서 나와야 「배선은 맞는데 갈래에 안 적힌 입력」이 안 생긴다.
## `test_player_scene.gd` 는 이 상수를 읽어 배선이 좌클릭 · `E` 인지 본다.
const USE_ACTION := InputRoute.USE_ACTION
const BAG_ACTION := InputRoute.BAG_ACTION

## 이 판의 씨앗. 저장·불러오기가 생기면 세이브에서 온다 (GDD D-1).
const WORLD_SEED := 20260914

@onready var _player: Player = $Player
@onready var _hotbar_view: HotbarView = $UI/Hotbar
@onready var _bag_view: BagView = $UI/Bag

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

## 가방 18칸. **핫바와 다른 객체다** (`Inventory` 머리말) — 합쳐서 27칸으로 세면
## 손에 못 드는 것이 손 칸을 먹는다.
##
## **밖에서 보인다**(`_` 가 없다): `measure_window.gd` 의 BAG 가 진짜 씬의 이 가방에
## 물건을 넣고 **화면에서 다시 읽는다**. 지금은 여기에 물건이 들어오는 길이 없다 —
## 바닥에 떨어진 것을 줍는 항목(BACKLOG P2)이 그 길을 낸다.
var bag := Inventory.new()

## **커서가 든 무더기** (회차 44). 가방이 열려 있는 동안만 쓴다 —
## 창을 닫으면 `_stow_grab()` 이 돌려놓는다.
##
## **밖에서 보인다**(`_` 가 없다): `measure_grab.gd` 가 진짜 씬의 이것을 읽어
## 「집었나 · 놓았나 · 합이 그대로인가」를 묻는다.
var grab := Grab.new()

## **사람이 차지한 칸** — 다시 자라는 나무가 여기에 묻는다 (GDD A-4).
## 지금 꽂히는 것은 몸 하나뿐이지만, **앞으로 놓이는 것 전부가 여기 줄을 선다**:
## 설치물 · 간 밭 · 길. 새 종류는 `Claim.KINDS` 에 이름을 적고 `_link_world()` 에서
## `add()` 로 꽂는다 — 적고 안 꽂으면 REGROW 게이트가 `missing()` 으로 잡는다.
##
## **밖에서 보인다**(`_` 가 없다): `measure_regrow.gd` 가 진짜 씬의 이 목록을 읽는다.
## 단위 검사는 제 Callable 을 손으로 꽂으므로 **여기서 한 줄을 빼먹어도 전부 초록**이다
## (회차 30 이 시계에서 겪은 그 구멍 — `Sky` 를 안 물들이는 것과도 같은 모양이다).
var claim := Claim.new()

## 숫자키의 **직전 프레임 상태**. 눌린 순간에만 손이 움직인다.
## **`is_action_just_pressed` 를 안 쓴다**: 「눌린 프레임」이 딱 한 번뿐이라
## `_process` 가 그 프레임을 비껴가면 아무 일도 안 일어난다 — 실측 게이트는
## `Input.action_press` 로 키를 몇 프레임 눌러 두므로 그 창에 걸린다.
var _key_down := PackedByteArray()

## `E` 의 직전 프레임 상태. 같은 이유로 든다 (`_poll_bag`).
var _bag_down := false

## 좌클릭의 **직전 프레임 상태** (회차 44). 휘두르는 쪽은 「누르는 동안 내내」라
## 이게 필요 없었지만, **집어서 놓기는 「눌린 순간」에 한 번**이다 — 누르고 있으면
## 한 프레임에 한 번씩 집었다 놓았다 한다.
## **죽어 있는 동안에도 적는다** (회차 43 이 숫자키에서 배운 그 자리): 안 적으면
## 창을 닫는 그 프레임에 쥐고 있던 버튼이 새 클릭으로 읽힌다.
var _use_down := false

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
	# **창을 게임 크기에 맞춘다** (회차 33). 사람이 두 번 지적한 자리다 —
	# 창 override 1920×1080 은 이 화면에서 가로의 절반밖에 안 덮었고, 앞 회차가 켠
	# 전체 화면은 3456 ÷ 960 = 3.6 의 소수점 아래를 576×548 px 의 띠로 버렸다.
	# 배율은 여기서 안 건다: `scale_mode=integer` 가 창 크기에서 제가 내림한다 —
	# 창을 정확히 `논리 × N` 으로 주면 그 내림이 딱 N 이라 **띠가 0 이다**.
	# `Display` 는 그 결과를 **미리 말해 두는 쪽**이고, VIEW 게이트가 엔진이 실제로
	# 건 배율·창·띠와 맞대 본다 (Display 머리말).
	Display.fit_window(get_window())
	_link_world()
	_key_down.resize(Hotbar.SLOTS)
	_hotbar_view.hotbar = hotbar
	_hotbar_view.queue_redraw()
	# **가방은 닫힌 채로 시작한다.** 씬의 글자에만 맡기지 않는다 — 여기가 출처면
	# 씬을 누가 건드려도 게임은 닫힌 채로 뜬다.
	_bag_view.inventory = bag
	_bag_view.grab = grab
	_bag_view.visible = false
	var vis := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	print(Display.report())
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
	print("CLAIM    차지 출처 %d 종 %s · 선언 %d 종 · 안 꽂힌 것 %s" % [
		claim.count(), str(claim.names()), Claim.KINDS.size(),
		"없다" if claim.missing().is_empty() else str(claim.missing())])
	print("DAY      하루 %.0f s (낮 %.0f + 밤 %.0f) · 시작 위상 %.2f (%s) · 여명 %.0f s" % [
		WorldState.DAY_SEC, WorldState.DAY_SEC * 0.5, WorldState.DAY_SEC * 0.5,
		DayCycle.phase(world.now), "낮" if DayCycle.is_day(world.now) else "밤",
		DayCycle.TWILIGHT * WorldState.DAY_SEC])

## **창이 열려 있나** — 지금은 가방 하나다. 입력 갈래를 묻는 쪽(`_poll_*`)은
## 「무슨 창인가」를 몰라야 한다: 상자 · 제작대가 생기면 여기에 `or` 하나가 붙고
## 폴링하는 세 곳은 한 줄도 안 고친다.
func _ui_open() -> bool:
	return _bag_view.is_open()

## 플레이어를 월드에 꽂는다. **이 줄이 없으면 바다 위를 걸어다닌다.**
##
## **Callable 을 한 번만 만든다**: `WorldState` 가 없앤 칸의 사전을 참조로 넘기므로,
## 나중에 벤 칸도 이미 꽂힌 이 Callable 이 그대로 본다.
func _link_world() -> void:
	_player.solid = world.solid()
	# **월드는 목록이 아니라 물음 하나만 안다.** 「누가 차지했나」는 `Claim` 의 것이다 —
	# 여기에 if 를 쌓으면 설치물이 생길 때마다 이 줄이 길어지고, 어느 회차가 조용히
	# 하나를 빼먹는다 (그게 「내 집 거실에 나무가 났다」로 나온다).
	claim.add(Claim.BODY, _body_covers)
	world.occupied = claim.covers
	world.changed.connect(_on_world_changed)

## 「이 칸에 몸이 서 있나」 — `Claim` 에 꽂히는 출처 하나다 (`Claim.BODY`).
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
	_poll_bag()
	_poll_use()
	queue_redraw()

## 숫자키 1..9 → 손. 액션 이름은 `Hotbar` 가 만든다 — 여기서 글자를 다시 적으면
## project.godot 의 배선과 갈라진다.
func _poll_hotbar() -> void:
	# **가방이 열려 있으면 손을 안 바꾼다** (`InputRoute`): 칸을 정리하다 손이 바뀌면
	# 창을 닫은 다음 좌클릭이 딴 도구를 쓴다.
	var live := InputRoute.is_live(InputRoute.HOTBAR, _ui_open())
	for i in Hotbar.SLOTS:
		var down: int = 1 if Input.is_action_pressed(Hotbar.action_for(i)) else 0
		# **직전 프레임은 죽어 있는 동안에도 적는다.** 안 적으면 가방을 연 채 누른
		# 키가 「안 눌렸던 것」으로 남아, 창을 닫는 순간 그 키가 손을 옮긴다 —
		# 사람은 아무것도 안 눌렀는데 도구가 바뀐다.
		if down == 1 and _key_down[i] == 0 and live:
			hotbar.select(i)
			_hotbar_view.queue_redraw()
		_key_down[i] = down

## `E` → 가방을 열고 닫는다. **숫자키와 같은 이유로 직전 프레임을 들고 폴링한다**:
## `is_action_just_pressed` 는 「눌린 프레임」이 딱 한 번뿐이라 실측 게이트가
## 눌러 두는 창을 비껴간다. 여기서는 그 실수가 더 나쁘다 — 토글이라
## **한 번 누른 것이 두 번 먹히면** 창이 열렸다 닫힌 것처럼 보인다.
## **이 키는 창이 열려 있어도 산다** (`InputRoute.BAG`) — 죽으면 한 번 연 창을
## 못 닫는다. 그래도 **표에 묻는다**: 안 물으면 그 줄은 아무도 안 읽는 죽은 줄이 되고,
## 창이 늘 때(상자 · 제작대) 「무엇으로 닫나」를 여기에 다시 적게 된다.
func _poll_bag() -> void:
	var down := Input.is_action_pressed(BAG_ACTION)
	if down and not _bag_down and InputRoute.is_live(InputRoute.BAG, _ui_open()):
		# **닫기 전에 든 것을 돌려놓는다** (회차 44). 커서는 화면의 것이라 창이
		# 닫히면 그릴 자리가 없다 — 여기가 없으면 「집은 채로 닫으면 사라진다」가
		# 한 글자도 안 틀리고 짜여진다. 닫을 때만이 아니라 **뒤집기 전에** 부른다:
		# 여는 쪽에서는 손이 늘 비어 있으므로 아무 일도 안 일어난다.
		_stow_grab()
		_bag_view.toggle()
	_bag_down = down

## 커서가 든 것을 가방 → 핫바 순으로 돌려놓는다. **못 넣은 몫은 바닥에 떨군다** —
## `Inventory.add` 가 「남은 개수」를 돌려주는 것과 같은 자리고, 벌목이 이미 그 길이다
## (`Harvest.hit`). 떨구는 것까지 실패하면 **손에 그대로 둔다**: 여기서 지우는 것이
## 곧 증발이다.
##
## 집으면 그 칸이 비므로 실제로는 늘 들어간다 — 그래도 남는 쪽을 적어 둔다.
## 상자·제작대가 생기면 받을 곳이 늘어서 그 전제가 흔들린다.
func _stow_grab() -> void:
	if grab.stow([bag, hotbar.items]) <= 0:
		return
	if world.add_drop(grab.id, grab.amount, _player.position):
		grab.clear()

## 좌클릭 → **창이 닫혀 있으면 손에 든 것의 동작, 열려 있으면 칸을 집고 놓기.**
##
## **한 버튼에 두 박자가 있다.** 휘두르는 쪽은 「누르는 동안 내내」고(HandSwing
## 머리말 — 겹치지 않게 막는 것은 `HandSwing.start()` 다), 집어서 놓기는
## 숫자키처럼 **「눌린 순간」에 한 번**이다. 그래서 `down` 과 `pressed` 를 둘 다 낸다.
func _poll_use() -> void:
	var down := Input.is_action_pressed(USE_ACTION)
	# **눌린 순간**은 집어서 놓기의 것이다. 직전 프레임은 **갈래와 상관없이** 적는다
	# (회차 43 이 숫자키에서 배운 자리) — 안 적으면 쥔 채로 창을 여닫는 프레임에
	# 사람이 안 누른 클릭이 한 번 생긴다.
	var pressed := down and not _use_down
	_use_down = down
	# **가방이 열려 있으면 휘두르지 않는다** — 그 클릭은 UI 의 것이다 (`InputRoute`).
	# 회차 44 부터 그 UI 가 있다: 커서 아래의 칸을 집고 놓는다.
	if not InputRoute.is_live(InputRoute.USE, _ui_open()):
		if pressed:
			grab_at(get_viewport().get_mouse_position())
		return
	if not down:
		return
	# **모션이 이번에 시작됐을 때만 판정한다.** `use()` 가 false 면 이미 휘두르는
	# 중이라, 여기서 또 판정하면 한 번의 동작이 프레임 수만큼 맞힌다 —
	# 나무 한 그루가 한 모션에 통째로 사라진다 (Harvest 머리말).
	if not _player.use(HandSwing.color_for(hotbar.held_id())):
		return
	Harvest.hit(world, hotbar.held_id(), _player.position, _player.facing)

## **화면의 점 하나를 칸으로 읽어 집거나 놓는다** (회차 44). 돌려주는 것은
## **무엇인가 바뀌었나**다 — 칸이 아닌 자리를 누르면 false 고 아무 일도 안 난다.
##
## **어느 창이냐를 가르는 유일한 곳이다.** 가방이 먼저다: 창이 핫바 위에 뜨지만
## 둘은 안 겹치므로(`test_bag_view.gd`) 순서가 결과를 안 바꾼다 — 그래도 못을 박는다.
## 상자·제작대가 생기면 그 줄이 여기 붙는다.
##
## **밖에서 부를 수 있다**(`_` 가 없다): `measure_grab.gd` 가 `BagView.slot_rect` 로
## 낸 진짜 화면 점을 밀어 넣는다. 커서를 읽는 줄(`get_viewport().get_mouse_position()`)은
## 게이트가 SubViewport 에 밀어 넣은 이벤트로 함께 잰다.
func grab_at(point: Vector2) -> bool:
	var screen := get_viewport().get_visible_rect().size
	var moved := false
	var i := BagView.slot_at(point, screen)
	if i >= 0:
		moved = grab.click(bag, i)
	else:
		i = HotbarView.slot_at(point, screen)
		if i >= 0:
			moved = grab.click(hotbar.items, i)
	if moved:
		_bag_view.queue_redraw()
		_hotbar_view.queue_redraw()
	return moved

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
