extends MeasurePhase

## **실측 게이트 — 칸 사이로 아이템을 옮긴다** (회차 44). 진짜 메인 씬에 `E` 로 가방을
## 열고, **커서를 진짜 칸 자리로 옮겨** 좌클릭으로 집고 놓는다.
##
## 왜 단위 검사로 부족한가: `Grab` 은 순수 계산이라 「합이 안 변하나」밖에 못 잰다.
## **`main.gd` 가 클릭을 그 계산에 안 이어도 단위 검사 228개는 전부 초록이다** —
## 사람 눈에는 「가방을 열었는데 아무것도 안 집힌다」로만 보인다. 회차 3 의 속도,
## 5 의 방향, 24 의 배치, 30 의 시계, 43 의 갈래와 **같은 모양의 구멍**이다.
##
## ── **제 SubViewport 를 세운다** (FACE 와 같은 이유) ─────────────────
## 루트 뷰포트의 `get_mouse_position()` 은 **매번 OS 커서를 되묻는다** — 헤드리스에서는
## 늘 (0,0) 이고, 창을 띄우면 사람이 마우스를 건드릴 때마다 튄다 (회차 8~11 이
## 네 회차를 잡아먹은 자리다). SubViewport 는 **밀어 넣은 이벤트만** 본다.
## 그래서 `main.gd` 는 여기서도 진짜로 `get_viewport().get_mouse_position()` 을
## 거친다 — 커서를 읽는 그 줄까지 이 게이트 안에 들어온다.
##
## **버튼은 `Input.action_press` 로 누른다.** 그쪽은 전역이라 뷰포트와 상관없이 간다:
## 커서는 뷰포트의 것, 버튼은 Input 싱글턴의 것 — 둘이 여기서 만난다.
##
## `root.gui_disable_input` 은 안 건드린다. FACE 가 그걸 끄는 것은 **창을 띄운 채로도**
## 돌 수 있게 하려던 방어였는데, 이 게이트는 헤드리스 묶음 안에 있어서 진짜 입력이
## 닿을 길이 없다 — 전역 플래그를 켜고 끄면 뒤 구간이 그걸 물려받는다.
##
## ── 여덟 구간. **뒤 둘이 대조군이다** ───────────────────────────────
##   ① 가방 0번 칸을 집는다        — 커서가 그 칸 위에 있어야 집힌다
##   ② 핫바 9번 칸에 놓는다        — **가방 ↔ 핫바를 오간다.** 커서 자리를 안 읽으면
##                                   0번 칸에 놓여서 여기가 빨개진다
##   ③ 가방 1번 칸을 집는다        — 다음 둘의 손을 채운다
##   ④ **꽉 찬 칸에 놓는다**       — 한 톨도 안 들어가고 **손에 그대로 남는다**
##                                   (BACKLOG 의 대조판 그 문장이다)
##   ⑤ 칸이 아닌 자리를 누른다     — 아무 일도 안 난다. -1 이 없으면 0번 칸이 집힌다
##   ⑥ **집은 채로 가방을 닫는다** — 든 것이 돌아온다 (BACKLOG 의 두 번째 대조판)
##   ⑦ **닫은 뒤 핫바를 누른다**   — 안 집힌다. 대신 **휘두른다**
##   ⑧ 그 클릭이 정말 갔나         — ⑦ 의 휘두른 프레임 수가 0 이 아니어야 한다.
##                                   없으면 ⑦ 은 「클릭이 애초에 안 갔다」와 못 가른다
##
## **매 구간 「합」을 잰다**: 가방 + 핫바 + 커서 + 바닥. 옮겼다는 것만 보면 꽉 찬 칸에
## 부은 몫이 어디로 갔는지 아무도 안 묻는다 — 이 게이트가 지키는 것은 그 합 하나다.
##
## **허용치가 하나도 없다.** 재는 것이 개수와 칸 번호뿐이라 잡음이 낄 자리가 없다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const WARMUP := 3          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다
const TOGGLE_SEC := 0.10   # E 를 쥐고 있는 시간. 토글은 **눌린 순간**에 한 번만 먹는다
const CLICK_SEC := 0.10    # 좌클릭을 쥐고 있는 시간. 집기도 **눌린 순간**에 한 번이다
const SWING_SEC := 0.10    # ⑦ 의 클릭. 한 모션(0.24초)보다 짧아서 구간 내내 휘두른다

## 넣어 둘 두 가지. **월드에서 나올 수 없는 아이디다** — `Harvest.WOOD` 를 쓰면
## 마지막 구간의 휘두르기가 나무를 베는 날 바닥의 목재가 합에 섞인다.
const ITEM_A := &"grab_a"
const ITEM_B := &"grab_b"
const A_N := 7             # 가방 0번 칸에 놓을 개수
const B_N := 5             # 가방 1번 칸에 놓을 개수

const BAG_FROM := 0        # 집을 가방 칸
const BAG_B := 1           # 두 번째로 집을 가방 칸
const HOT_TO := 8          # 놓을 핫바 칸. **0 이 아니어야** 커서를 읽는지가 갈린다
const HOT_FULL := 0        # 꽉 채워 둘 핫바 칸 (STACK_MAX)

## 칸이 아닌 자리. 화면 왼쪽 위 모서리라 가방 창에서도 핫바에서도 한참 멀다.
const NO_SLOT := Vector2(4.0, 4.0)

var _view: SubViewport
var _main: Node
var _player: Node2D
var _bag: Control
var _screen := Vector2.ZERO
var _frames := 0
var _t := 0.0
var _stage := 0
var _watched := 0
var _swing_frames := 0
var _sum0 := 0             # 처음의 합. **모든 구간이 이 수와 견준다**
var _pending := &""        # 다음 프레임에 누를 액션 (`_press_soon`)
var _done := false

func tag() -> String:
	return "GRAB"

## 메인 씬을 루트가 아니라 **SubViewport 안에** 세운다 (머리말). 논리 화면과 같은
## 크기라 `BagView.slot_rect` 가 내는 자리가 게임과 글자 그대로 같다.
func begin(t: SceneTree) -> void:
	super(t)
	_view = SubViewport.new()
	_view.size = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	_view.handle_input_locally = true
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_view.add_child(load(scene).instantiate())
	tree.root.add_child(_view)

func cleanup() -> void:
	super()
	if _main != null:
		Input.action_release(_main.USE_ACTION)
		Input.action_release(_main.BAG_ACTION)
	drop(_view)
	_view = null
	_main = null
	_player = null
	_bag = null

func step(delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	if _done:
		return true
	# **누르기는 한 프레임 미룬다** (`_press_soon`). 구간 핸들러는 놓자마자 다시
	# 누르는데, 이 스크립트의 `step` 은 **노드의 `_process` 보다 먼저** 돈다 —
	# 한 프레임 안에서 놓고 누르면 `main.gd` 는 「놓았다」를 한 번도 못 보고,
	# **눌린 순간**이 영영 안 온다. 집어서 놓기는 그 순간에만 먹는다
	# (2026-09-16 실측: 안 미루면 첫 클릭만 먹고 나머지 일곱이 통째로 죽는다).
	if _pending != &"":
		Input.action_press(_pending)
		_pending = &""
	_t += delta
	_watched += 1
	if _player.swing.is_swinging():
		_swing_frames += 1
	match _stage:
		0:
			if _t >= TOGGLE_SEC:
				return _opened()
		1:
			if _t >= CLICK_SEC:
				return _took_from_bag()
		2:
			if _t >= CLICK_SEC:
				return _put_in_hotbar()
		3:
			if _t >= CLICK_SEC:
				return _took_second()
		4:
			if _t >= CLICK_SEC:
				return _put_on_full()
		5:
			if _t >= CLICK_SEC:
				return _clicked_nothing()
		6:
			if _t >= TOGGLE_SEC:
				return _closed_holding()
		7:
			if _t >= SWING_SEC:
				return _clicked_while_shut()
	return false

## 노드를 집고 **물건을 넣고** 가방을 연다. 여기서 죽으면 아래 판정은 전부 공허하다.
func _setup() -> bool:
	_main = _view.get_node_or_null("Main")
	if _main != null:
		_player = _main.get_node_or_null("Player") as Node2D
		_bag = _main.get_node_or_null("UI/Bag") as Control
	if _main == null or _player == null or _bag == null:
		fail("씬", "Main %s · Player %s · UI/Bag %s" % [_main, _player, _bag],
			"SubViewport 안에 셋 다")
		return _stop()
	_screen = _view.get_visible_rect().size
	if _screen != Vector2(960.0, 540.0):
		fail("SubViewport 크기", str(_screen), "논리 화면 960 x 540 (NUMBERS 1절)")
		return _stop()
	if _bag.visible:
		fail("시작 상태", "가방이 이미 열려 있다", "닫혀 있다")
		return _stop()
	if not _main.grab.is_empty():
		fail("시작 상태", "커서가 %s 를 들고 있다" % _main.grab.id, "빈 손")
		return _stop()
	# **가방 앞 두 칸과 핫바 한 칸을 채운다.** `add` 가 앞 칸부터 채우므로 자리가 정해진다.
	_main.bag.add(ITEM_A, A_N)
	_main.bag.add(ITEM_B, B_N)
	_main.hotbar.items.add(ITEM_B, Inventory.STACK_MAX)
	if _main.bag.ids[BAG_FROM] != ITEM_A or _main.bag.ids[BAG_B] != ITEM_B \
			or _main.hotbar.items.amounts[HOT_FULL] != Inventory.STACK_MAX:
		fail("차려 놓기", "가방 %s/%s · 핫바 %d개" % [
			_main.bag.ids[BAG_FROM], _main.bag.ids[BAG_B],
			_main.hotbar.items.amounts[HOT_FULL]],
			"가방 0=%s · 1=%s · 핫바 0=%d개" % [ITEM_A, ITEM_B, Inventory.STACK_MAX])
		return _stop()
	_sum0 = _sum()
	print("GRAB 화면 %s · 합 %d개 (가방 %d + 핫바 %d) · 칸 가방%d→핫바%d · 꽉 찬 칸 핫바%d" % [
		_screen, _sum0, _main.bag.total(), _main.hotbar.items.total(),
		BAG_FROM + 1, HOT_TO + 1, HOT_FULL + 1])
	_press_soon(_main.BAG_ACTION)
	return _next(0)

## 가방이 열렸다. 커서를 **가방 0번 칸 한가운데**로 옮기고 좌클릭을 누른다.
func _opened() -> bool:
	Input.action_release(_main.BAG_ACTION)
	if not _bag.visible:
		fail("E 를 눌렀다", "가방이 안 열렸다", "열린다")
		return _stop()
	_aim(BagView.slot_rect(BAG_FROM, _screen).get_center())
	_press_soon(_main.USE_ACTION)
	return _next(1)

## ① **가방 0번 칸을 집었다.** 커서가 그 칸 위에 있었으므로 통째로 손에 온다.
func _took_from_bag() -> bool:
	Input.action_release(_main.USE_ACTION)
	var ok: bool = _main.grab.id == ITEM_A and _main.grab.amount == A_N \
		and _main.bag.ids[BAG_FROM] == Inventory.EMPTY
	if not ok:
		fail("가방 %d번 칸 집기" % (BAG_FROM + 1),
			"커서 %s %d개 · 그 칸 %s %d개" % [_main.grab.id, _main.grab.amount,
				_main.bag.ids[BAG_FROM], _main.bag.amounts[BAG_FROM]],
			"커서 %s %d개 · 그 칸은 빈다" % [ITEM_A, A_N])
	_say("집기", "커서 %s %d개 · 가방 %d번 칸 %s" % [
		_main.grab.id, _main.grab.amount, BAG_FROM + 1, _main.bag.ids[BAG_FROM]], ok)
	_aim(HotbarView.slot_rect(HOT_TO, _screen).get_center())
	_press_soon(_main.USE_ACTION)
	return _next(2)

## ② **핫바 9번 칸에 놓았다 — 가방 ↔ 핫바를 오간다.**
## 커서 자리를 안 읽으면 0번 칸(꽉 찬 칸)으로 가서 여기가 빨개진다.
func _put_in_hotbar() -> bool:
	Input.action_release(_main.USE_ACTION)
	var ok: bool = _main.hotbar.items.ids[HOT_TO] == ITEM_A \
		and _main.hotbar.items.amounts[HOT_TO] == A_N and _main.grab.is_empty()
	if not ok:
		fail("핫바 %d번 칸에 놓기" % (HOT_TO + 1),
			"그 칸 %s %d개 · 커서 %s %d개" % [_main.hotbar.items.ids[HOT_TO],
				_main.hotbar.items.amounts[HOT_TO], _main.grab.id, _main.grab.amount],
			"그 칸 %s %d개 · 커서는 빈다" % [ITEM_A, A_N])
	var sum_ok := _same_sum("놓기")
	_say("놓기", "핫바 %d번 칸 %s %d개 · 커서 비었나 %s" % [
		HOT_TO + 1, _main.hotbar.items.ids[HOT_TO], _main.hotbar.items.amounts[HOT_TO],
		_main.grab.is_empty()], ok and sum_ok)
	_aim(BagView.slot_rect(BAG_B, _screen).get_center())
	_press_soon(_main.USE_ACTION)
	return _next(3)

## ③ 두 번째 칸을 집는다 — ④⑤⑥ 의 손을 채우는 구간이다.
func _took_second() -> bool:
	Input.action_release(_main.USE_ACTION)
	var ok: bool = _main.grab.id == ITEM_B and _main.grab.amount == B_N
	if not ok:
		fail("가방 %d번 칸 집기" % (BAG_B + 1),
			"커서 %s %d개" % [_main.grab.id, _main.grab.amount],
			"커서 %s %d개" % [ITEM_B, B_N])
		return _stop()
	_aim(HotbarView.slot_rect(HOT_FULL, _screen).get_center())
	_press_soon(_main.USE_ACTION)
	return _next(4)

## ④ **꽉 찬 칸에 놓았다 — 한 톨도 안 들어가고 손에 그대로 남는다.**
## BACKLOG 의 대조판이다: 「꽉 찬 칸에 놓아서 개수가 줄어드는지」.
func _put_on_full() -> bool:
	Input.action_release(_main.USE_ACTION)
	var there: int = _main.hotbar.items.amounts[HOT_FULL]
	var ok: bool = there == Inventory.STACK_MAX \
		and _main.grab.id == ITEM_B and _main.grab.amount == B_N
	if not ok:
		fail("꽉 찬 칸에 놓기",
			"그 칸 %d개 · 커서 %s %d개" % [there, _main.grab.id, _main.grab.amount],
			"그 칸 %d개 그대로 · 커서 %s %d개 그대로" % [Inventory.STACK_MAX, ITEM_B, B_N])
	var sum_ok := _same_sum("꽉 찬 칸")
	_say("꽉 찬 칸", "핫바 %d번 칸 %d개 · 커서 %s %d개" % [
		HOT_FULL + 1, there, _main.grab.id, _main.grab.amount], ok and sum_ok)
	_aim(NO_SLOT)
	_press_soon(_main.USE_ACTION)
	return _next(5)

## ⑤ **칸이 아닌 자리를 눌렀다 — 아무 일도 안 난다.**
## `slot_at` 이 -1 을 안 내면 빗나간 클릭이 0번 칸을 집는다.
func _clicked_nothing() -> bool:
	Input.action_release(_main.USE_ACTION)
	var ok: bool = _main.grab.id == ITEM_B and _main.grab.amount == B_N \
		and _main.bag.ids[BAG_FROM] == Inventory.EMPTY
	if not ok:
		fail("칸이 아닌 자리 %s" % NO_SLOT,
			"커서 %s %d개 · 가방 %d번 칸 %s" % [_main.grab.id, _main.grab.amount,
				BAG_FROM + 1, _main.bag.ids[BAG_FROM]],
			"커서 %s %d개 그대로 · 가방 %d번 칸은 빈 채로" % [ITEM_B, B_N, BAG_FROM + 1])
	var sum_ok := _same_sum("빈 자리 클릭")
	_say("빈 자리 클릭", "커서 %s %d개" % [_main.grab.id, _main.grab.amount], ok and sum_ok)
	# ⑥ 로 넘어간다: **든 채로** 가방을 닫는다.
	_press_soon(_main.BAG_ACTION)
	return _next(6)

## ⑥ **집은 채로 가방을 닫았다 — 든 것이 돌아온다.**
## BACKLOG 의 두 번째 대조판이다: 「집은 채로 가방을 닫아서 잃어버리는지」.
func _closed_holding() -> bool:
	Input.action_release(_main.BAG_ACTION)
	if _bag.visible:
		fail("E 를 다시 눌렀다", "가방이 안 닫혔다", "닫힌다")
		return _stop()
	var back: int = _main.bag.count(ITEM_B) + _main.hotbar.items.count(ITEM_B)
	var ok: bool = _main.grab.is_empty() and back == Inventory.STACK_MAX + B_N
	if not ok:
		fail("든 채로 닫기",
			"커서 %s %d개 · 칸에 있는 %s %d개" % [_main.grab.id, _main.grab.amount, ITEM_B, back],
			"커서는 비고 %s 가 %d개 (핫바의 %d + 든 %d)" % [
				ITEM_B, Inventory.STACK_MAX + B_N, Inventory.STACK_MAX, B_N])
	var sum_ok := _same_sum("든 채로 닫기")
	_say("든 채로 닫기", "커서 비었나 %s · %s 총 %d개 · 바닥 %d개" % [
		_main.grab.is_empty(), ITEM_B, back, _main.world.dropped_total(ITEM_B)],
		ok and sum_ok)
	# **여기부터가 대조군이다** — 닫힌 채로 같은 칸 자리를 같은 길이로 누른다.
	_aim(HotbarView.slot_rect(HOT_TO, _screen).get_center())
	_press_soon(_main.USE_ACTION)
	return _next(7)

## ⑦⑧ **대조군 — 닫은 뒤의 좌클릭은 안 집고 휘두른다.**
## ⑧ 이 없으면 ⑦ 은 「클릭이 애초에 안 갔다」와 구별되지 않는다 (회차 29·43).
func _clicked_while_shut() -> bool:
	Input.action_release(_main.USE_ACTION)
	var held: int = _main.hotbar.items.amounts[HOT_TO]
	var ok: bool = _main.grab.is_empty() and held == A_N
	if not ok:
		fail("닫은 뒤 핫바 클릭 (대조군)",
			"커서 %s %d개 · 그 칸 %d개" % [_main.grab.id, _main.grab.amount, held],
			"커서는 비고 그 칸은 %d개 그대로 (닫혀 있으면 안 집힌다)" % A_N)
	var swung := _swing_frames > 0
	if not swung:
		fail("닫은 뒤 휘두르기 (대조군)", "휘두른 프레임 %d (%d 프레임 중)" % [
			_swing_frames, _watched], "한 프레임 이상 — 안 그러면 ⑦ 이 공허하다")
	var sum_ok := _same_sum("닫은 뒤 클릭")
	_say("닫은 뒤 클릭", "커서 비었나 %s · 핫바 %d번 칸 %d개 · 휘두른 프레임 %d/%d" % [
		_main.grab.is_empty(), HOT_TO + 1, held, _swing_frames, _watched],
		ok and swung and sum_ok)
	print("GRAB %s (구간 8 · 합 %d개 · 허용치 없다 · SubViewport 960x540 에 합성 커서)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, _sum0])
	_done = true
	return true

## **가방 + 핫바 + 커서 + 바닥.** 이 수가 변하면 어딘가에서 증발했거나 늘어났다.
##
## 구간마다 **먼저 재고 나서** 판정과 `and` 로 묶는다 — `ok and _same_sum(...)` 로 쓰면
## 판정이 빨간 구간에서는 합을 아예 안 재고 넘어간다 (단락 평가).
func _sum() -> int:
	return _main.bag.total() + _main.hotbar.items.total() + _main.grab.total() \
		+ _main.world.dropped_total(ITEM_A) + _main.world.dropped_total(ITEM_B)

func _same_sum(what: String) -> bool:
	var now := _sum()
	if now == _sum0:
		return true
	fail("%s 뒤의 합" % what, "%d개" % now, "%d개 — 한 톨도 안 변해야 한다" % _sum0)
	return false

## **다음 프레임에** 이 액션을 누른다. 왜 미루는지는 `step` 의 주석에 있다.
func _press_soon(action: StringName) -> void:
	_pending = action

## 커서를 그 화면 점으로 옮긴다. **합성 이벤트다** — OS 커서는 안 건드린다.
func _aim(point: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = point
	ev.global_position = point
	_view.push_input(ev)

func _next(stage: int) -> bool:
	_stage = stage
	_t = 0.0
	_watched = 0
	_swing_frames = 0
	return false

func _say(what: String, got: String, ok: bool) -> void:
	if not ok:
		bad += 1
	print("GRAB %s  %s  %s" % [what, got, "ok" if ok else "FAIL"])

## 게이트가 죽을 때도 **제 요약 줄을 남긴다** — 침묵은 초록으로 읽히면 안 된다.
func _stop() -> bool:
	bad += 1
	print("GRAB FAIL %d개 (칸 사이로 옮겨 보지도 못했다)" % bad)
	_done = true
	return true
