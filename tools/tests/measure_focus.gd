extends MeasurePhase

## **실측 게이트 — 가방이 열려 있는 동안의 입력.** 진짜 메인 씬에 `E` 를 눌러 창을 열고,
## 그 상태로 **좌클릭 · 숫자키 · WASD** 를 눌러서 무엇이 살아 있는지 잰다.
##
## 왜 단위 검사로 부족한가: `InputRoute` 는 순수한 표라 「표가 맞나」밖에 못 잰다.
## **`main.gd` 가 그 표를 안 묻고 넘어가도 단위 검사 202개는 전부 초록이다** —
## 사람 눈에는 「가방을 정리하다 나무를 베고 손이 바뀐다」로만 보인다. 회차 3 의 속도,
## 5 의 방향, 24 의 배치, 30 의 시계와 **같은 모양의 구멍**이다.
##
## **다섯 가지를 한 번에 본다** — 앞 셋은 가방을 연 채, 뒤 둘은 닫은 뒤다:
##   ① 열린 채 좌클릭 — **휘두르는 네모가 한 프레임도 안 나온다**(BACKLOG 의 대조판
##      그 문장이다) · 판정도 안 돈다(벤 칸이 안 는다)
##   ② 열린 채 숫자키 — **손이 그 칸에 그대로** 있다
##   ③ 열린 채 WASD  — **걸린다.** 코어 키퍼 방식이다. 이것이 없으면 ①②는 그냥
##      「입력을 통째로 막았다」고, 그건 다른 게임이다
##   ④ **누른 채로 닫는다** — 열린 채 쥐고 있던 숫자키는 창이 닫히는 순간에도
##      손을 안 옮긴다. 「죽은 동안의 입력을 안 적고 넘어가면」 사람이 아무것도 안
##      누른 그 프레임에 도구가 바뀐다 — 눌렀다 뗐다만 재면 이 구멍이 안 보인다
##   ⑤ 닫은 뒤 좌클릭 — **휘두른다** ⑥ 닫은 뒤 숫자키 — **손이 바뀐다**
##
## **⑤⑥ 가 없으면 ①② 는 공허한 대조군이다** (회차 29 가 CHOP 의 맨손에서 배운 것):
## 클릭이 애초에 안 갔거나 키가 안 묶였어도 「안 휘둘렀다 · 손이 그대로다」는 맞는 말이
## 된다. 같은 길이로 같은 키를 눌러서 **한쪽은 나오고 한쪽은 안 나오는 것**을 본다.
##
## **허용치가 하나도 없다.** 재는 것이 「프레임 수 0 인가」와 「움직인 px 가 0 이 아닌가」
## 뿐이라 잡음이 낄 자리가 없다: 입력이 막히면 정확히 0.0 px 고, 살아 있으면 0.30초에
## 72 px 다. 그래서 `Tol.obs` 로 흘릴 수가 없다 — **여기에 허용치를 새로 만들면
## `test_tolerances.gd` 의 파일 목록에 이 파일을 적고 `Tol.obs` 로 흘려야 한다.**
##
## 헤드리스로 된다 — 창도 커서도 필요 없다. 픽셀을 안 본다: 네모가 `visible` 이 아니면
## 그릴 수가 없고, 「보이면 픽셀에 나온다」는 USE 게이트가 이미 지킨다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const WARMUP := 3          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다 (measure_chop 과 같다)
const TOGGLE_SEC := 0.10   # E 를 쥐고 있는 시간. 토글은 **눌린 순간**에 한 번만 먹는다
const CLICK_SEC := 0.40    # 좌클릭을 쥐고 있는 시간. 한 모션(0.24초)이 끝나고도 남는다
const KEY_SEC := 0.10      # 숫자키를 쥐고 있는 시간
const WALK_SEC := 0.30     # 걷는 시간. 240 px/s 면 72 px = 4.5칸
const HB_KEY := 3          # 눌러 볼 숫자키. 처음 든 1번 칸과 달라야 옮겨간 것이 보인다
## **누른 채로 가방을 닫아 볼** 숫자키. HB_KEY 와 달라야 어느 키가 손을 옮겼는지 갈린다.
const HOLD_KEY := 5
## 이만큼이라도 움직였으면 「걸었다」. **허용치가 아니다**: 입력이 막히면 속도가 통째로
## 0 이라 정확히 0.0 px 이고, 안 막히면 0.30초에 72 px 다.
const WALK_MIN := 1.0
const SEARCH := 3          # 걸어갈 빈 방향을 찾을 때 앞을 몇 칸 보나

var _main: Node
var _player: Node2D
var _bag: Control
var _tool: ColorRect
var _frames := 0
var _t := 0.0
var _stage := 0
var _watched := 0          # 이 구간에서 본 프레임 수
var _swing_frames := 0     # 그중 **휘두르고 있던** 프레임 수
var _tool_frames := 0      # 그중 네모가 **보였던** 프레임 수
var _cleared_before := 0
var _from := Vector2.ZERO
var _dir := Vector2i.RIGHT
var _walked := 0.0
var _done := false

func tag() -> String:
	return "FOCUS"

func begin(t: SceneTree) -> void:
	super(t)
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	tree.root.add_child(_main)

func cleanup() -> void:
	super()
	if _main != null:
		Input.action_release(_main.USE_ACTION)
		Input.action_release(_main.BAG_ACTION)
		Input.action_release(Hotbar.action_for(HB_KEY - 1))
		Input.action_release(Hotbar.action_for(HOLD_KEY - 1))
	drop(_main)
	_main = null
	_player = null
	_bag = null
	_tool = null

func step(delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	if _done:
		return true
	_t += delta
	# **프레임마다 본다.** 「한 프레임도 안 나온다」는 프레임마다 묻지 않으면 못 잰다 —
	# 한 모션은 0.24초라 구간 끝에서 한 번만 보면 이미 끝나 있다.
	_watched += 1
	if _player.swing.is_swinging():
		_swing_frames += 1
	if _tool.visible:
		_tool_frames += 1
	match _stage:
		0:
			if _t >= TOGGLE_SEC:
				return _opened()
		1:
			if _t >= CLICK_SEC:
				return _click_open()
		2:
			if _t >= KEY_SEC:
				return _key_open()
		3:
			if _t >= WALK_SEC:
				return _walk_open()
		4:
			if _t >= KEY_SEC:
				return _hold_open()
		5:
			if _t >= TOGGLE_SEC:
				return _closed()
		6:
			if _t >= KEY_SEC:
				return _held_after_close()
		7:
			if _t >= CLICK_SEC:
				return _click_shut()
		8:
			if _t >= KEY_SEC:
				return _key_shut()
	return false

## 노드를 집고 **가방을 연다.** 여기서 죽으면 아래 판정은 전부 공허하다.
func _setup() -> bool:
	_player = _main.get_node_or_null("Player")
	_bag = _main.get_node_or_null("UI/Bag") as Control
	if _player != null:
		_tool = _player.get_node_or_null("Tool") as ColorRect
	if _player == null or _bag == null or _tool == null:
		fail("씬", "Player %s · UI/Bag %s · Player/Tool %s" % [_player, _bag, _tool],
			"메인 씬에 셋 다")
		return _stop()
	if not _player.solid.is_valid():
		fail("배선", "player.solid 가 비어 있다 — main.gd 가 월드를 안 꽂았다", "WorldState.solid()")
		return _stop()
	# **표에 안 적힌 갈래가 있으면 그 입력은 창이 열려도 그대로 월드로 간다.**
	if not InputRoute.missing().is_empty():
		fail("갈래 표", "안 적힌 갈래 %s" % str(InputRoute.missing()), "없다")
	if _bag.visible:
		fail("시작 상태", "가방이 이미 열려 있다", "닫혀 있다 (E 를 눌러야 열린다)")
		return _stop()
	if _main.hotbar.selected != 0:
		fail("시작 상태", "손이 %d번 칸에 있다" % (_main.hotbar.selected + 1), "1번 칸")
		return _stop()
	if not _find_dir():
		return _stop()
	print("FOCUS 설 자리 %s · 걸어갈 쪽 %s (%d칸 비었다) · 갈래 %d종" % [
		_player.position, _dir, SEARCH, InputRoute.KINDS.size()])
	Input.action_press(_main.BAG_ACTION)
	return _next(0)

## 가방이 열렸다. 이제 **열린 채로** 좌클릭을 쥔다.
func _opened() -> bool:
	Input.action_release(_main.BAG_ACTION)
	if not _bag.visible:
		fail("E 를 눌렀다", "가방이 안 열렸다", "열린다 (main.gd 가 키를 읽나?)")
		return _stop()
	_cleared_before = _main.world.cleared_count()
	Input.action_press(_main.USE_ACTION)
	return _next(1)

## ① **열린 채 좌클릭 — 휘두르는 네모가 한 프레임도 안 나온다.**
func _click_open() -> bool:
	Input.action_release(_main.USE_ACTION)
	var cleared: int = _main.world.cleared_count() - _cleared_before
	var ok := true
	if _swing_frames != 0 or _tool_frames != 0:
		ok = false
		fail("열린 채 좌클릭", "휘두른 프레임 %d · 네모 보인 프레임 %d (%d 프레임 중)" % [
			_swing_frames, _tool_frames, _watched], "둘 다 0 (클릭은 UI 로 간다)")
	if cleared != 0:
		ok = false
		fail("열린 채 좌클릭의 판정", "칸 %d개가 없어졌다" % cleared, "0개 (판정도 안 돈다)")
	if _watched == 0:
		ok = false
		fail("열린 채 좌클릭", "%.2f초 동안 본 프레임 0" % _t, "한 프레임 이상")
	_say("열린 채 좌클릭", "%.2f초 · 본 프레임 %d · 휘두른 프레임 %d · 네모 보인 프레임 %d · 벤 칸 %d" % [
		_t, _watched, _swing_frames, _tool_frames, cleared], ok)
	Input.action_press(Hotbar.action_for(HB_KEY - 1))
	return _next(2)

## ② **열린 채 숫자키 — 손이 그대로다.**
func _key_open() -> bool:
	Input.action_release(Hotbar.action_for(HB_KEY - 1))
	var ok: bool = _main.hotbar.selected == 0
	if not ok:
		fail("열린 채 숫자키", "손이 %d번 칸으로 갔다" % (_main.hotbar.selected + 1),
			"1번 칸 그대로 (숫자키는 손을 안 바꾼다)")
	_say("열린 채 숫자키", "키 %d · 손 %d번 칸" % [HB_KEY, _main.hotbar.selected + 1], ok)
	_from = _player.position
	_press_walk()
	return _next(3)

## ③ **열린 채 WASD — 걸린다** (코어 키퍼 방식). 이것이 없으면 ①② 는 「입력을
## 통째로 막았다」는 뜻이고, 그러면 사람은 창을 열기를 겁낸다.
func _walk_open() -> bool:
	_release_walk()
	_walked = (_player.position - _from).length()
	var ok := _walked >= WALK_MIN
	if not ok:
		fail("열린 채 걷기", "%.2f초 동안 %.2f px" % [_t, _walked],
			"%.1f px 이상 (막히면 정확히 0.0 이다)" % WALK_MIN)
	_say("열린 채 걷기", "%.2f초 · %.2f px (%.2f칸) · %.1f px/s · 쪽 %s" % [
		_t, _walked, _walked / PlayerMotion.TILE, _walked / _t, _dir], ok)
	# ④ 로 넘어간다: **숫자키를 누른 채로** 가방을 닫아 본다.
	Input.action_press(Hotbar.action_for(HOLD_KEY - 1))
	return _next(4)

## ④ 앞쪽 — 열린 채 쥐고 있다. 아직 손은 그대로다 (② 와 같은 말이라 여기서는 안 센다).
func _hold_open() -> bool:
	# **키를 놓지 않고** E 를 누른다 — 쥔 채로 창이 닫히는 그 프레임이 겨누는 자리다.
	Input.action_press(_main.BAG_ACTION)
	return _next(5)

## 가방을 닫는다 — **숫자키를 쥔 채로.**
func _closed() -> bool:
	Input.action_release(_main.BAG_ACTION)
	if _bag.visible:
		fail("E 를 다시 눌렀다", "가방이 안 닫혔다", "닫힌다")
		return _stop()
	return _next(6)

## ④ **쥐고 있던 숫자키는 창이 닫히는 순간에도 손을 안 옮긴다.**
## 쥐고 있는 것은 「새로 누른 것」이 아니다 — 놓았다 다시 눌러야 먹는다.
## `main.gd` 가 **죽어 있는 동안에도 직전 프레임을 적는** 이유가 이 한 줄이다:
## 안 적으면 사람이 아무것도 안 누른 그 프레임에 도구가 바뀐다.
func _held_after_close() -> bool:
	var ok: bool = _main.hotbar.selected == 0
	if not ok:
		fail("누른 채로 닫았다", "손이 %d번 칸으로 갔다 (쥐고 있던 키 %d)" % [
			_main.hotbar.selected + 1, HOLD_KEY],
			"1번 칸 그대로 (닫는 프레임에 도구가 바뀌면 안 된다)")
	_say("누른 채로 닫기", "쥔 키 %d · 닫은 뒤 손 %d번 칸" % [
		HOLD_KEY, _main.hotbar.selected + 1], ok)
	Input.action_release(Hotbar.action_for(HOLD_KEY - 1))
	# **여기부터가 대조군이다** — 같은 키를 같은 길이로 누른다.
	Input.action_press(_main.USE_ACTION)
	return _next(7)

## ⑤ **대조군 — 닫은 뒤 좌클릭은 휘두른다.**
func _click_shut() -> bool:
	Input.action_release(_main.USE_ACTION)
	var ok := _swing_frames > 0 and _tool_frames > 0
	if not ok:
		fail("닫은 뒤 좌클릭 (대조군)",
			"휘두른 프레임 %d · 네모 보인 프레임 %d (%d 프레임 중)" % [
				_swing_frames, _tool_frames, _watched],
			"둘 다 한 프레임 이상 — 안 그러면 ① 이 공허하다")
	_say("닫은 뒤 좌클릭", "%.2f초 · 본 프레임 %d · 휘두른 프레임 %d · 네모 보인 프레임 %d" % [
		_t, _watched, _swing_frames, _tool_frames], ok)
	Input.action_press(Hotbar.action_for(HB_KEY - 1))
	return _next(8)

## ⑥ **대조군 — 닫은 뒤 숫자키는 손을 바꾼다.**
func _key_shut() -> bool:
	Input.action_release(Hotbar.action_for(HB_KEY - 1))
	var ok: bool = _main.hotbar.selected == HB_KEY - 1
	if not ok:
		fail("닫은 뒤 숫자키 (대조군)", "손이 %d번 칸이다" % (_main.hotbar.selected + 1),
			"%d번 칸 — 안 그러면 ② 가 공허하다" % HB_KEY)
	_say("닫은 뒤 숫자키", "키 %d · 손 %d번 칸" % [HB_KEY, _main.hotbar.selected + 1], ok)
	print("FOCUS %s (열린 채 셋 + 쥔 채로 닫기 + 닫은 뒤 둘 · 좌클릭 %.2f초 · 걷기 %.2f초 · 허용치 없다)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, CLICK_SEC, WALK_SEC])
	_done = true
	return true

## 한 구간을 끝내고 다음 구간을 연다 — **시계와 프레임 세는 것을 같이 0 으로 돌린다.**
func _next(stage: int) -> bool:
	_stage = stage
	_t = 0.0
	_watched = 0
	_swing_frames = 0
	_tool_frames = 0
	return false

func _say(what: String, got: String, ok: bool) -> void:
	if not ok:
		bad += 1
	print("FOCUS %s  %s  %s" % [what, got, "ok" if ok else "FAIL"])

func _press_walk() -> void:
	for a in _walk_actions():
		Input.action_press(a)

func _release_walk() -> void:
	for a in _walk_actions():
		Input.action_release(a)

## 고른 쪽의 이동 액션. **이름은 `InputRoute` 가 든다** — 여기서 글자를 다시 적으면
## 배선과 갈라진다.
func _walk_actions() -> Array:
	if _dir.x > 0:
		return [InputRoute.MOVE_ACTIONS[1]]
	if _dir.x < 0:
		return [InputRoute.MOVE_ACTIONS[0]]
	if _dir.y < 0:
		return [InputRoute.MOVE_ACTIONS[2]]
	return [InputRoute.MOVE_ACTIONS[3]]

## 앞이 **SEARCH 칸 비어 있는** 쪽을 고른다. 막힌 쪽으로 걸으면 「못 걸었다」가
## 갈래 탓인지 바다 탓인지 안 갈린다.
func _find_dir() -> bool:
	var here := Vector2i(WorldCollide.tile_of(_player.position.x),
		WorldCollide.tile_of(_player.position.y))
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var free := true
		for k in range(1, SEARCH + 1):
			var t: Vector2i = here + d * k
			if _player.solid.call(t.x, t.y) or _main.world.object_at(t.x, t.y) != WorldObjects.NONE:
				free = false
				break
		if free:
			_dir = d
			return true
	fail("걸어갈 쪽", "%s 둘레 %d칸이 네 쪽 다 막혔다" % [here, SEARCH], "한 쪽 이상")
	return false

## 게이트가 죽을 때도 **제 요약 줄을 남긴다** — 침묵은 초록으로 읽히면 안 된다.
func _stop() -> bool:
	bad += 1
	print("FOCUS FAIL %d개 (열린 채로 재 보지도 못했다)" % bad)
	_done = true
	return true
