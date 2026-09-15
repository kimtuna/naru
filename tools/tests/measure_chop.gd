extends MeasurePhase

## **실측 게이트 — 벌목.** 진짜 메인 씬을 돌려 **좌클릭을 쥐고** 나무를 벤다.
##
## 왜 단위 검사로 부족한가: `Harvest` 가 아무리 맞아도 **main.gd 가 그걸 안 부르면**
## 좌클릭은 모션만 나오고 나무는 그대로다 — 그런데 단위 검사는 전부 초록으로 남는다.
## (회차 3 의 속도, 5 의 방향, 회차 24 의 배치와 같은 모양의 구멍이다.)
##
## **다섯 가지를 한 번에 본다**:
##   ① **맨손으로는 안 베인다** — 그런데 **휘두르기는 한다.** 둘 다 봐야 대조군이
##      공허하지 않다: 클릭이 아예 안 갔으면 「안 베였다」는 아무 말도 아니다
##   ② 도끼를 들면 겨눈 칸의 나무가 **없어진다**
##   ③ 벤 칸이 **더 이상 안 막는다** — 걸어 들어갈 수 있다. 이게 없으면
##      「베었다」가 거짓말이고, 사람은 안 보이는 벽에 낀다
##   ④ **목재가 바닥에 떨어졌다** — 그 칸 한가운데에, 정해진 개수만큼
##   ⑤ **화면이 다시 칠해졌다**(`cache_fills`). 헤드리스라 픽셀은 못 읽지만,
##      색 캐시는 「보이는 범위가 바뀔 때만」 채우므로 **제자리에 서서 베면
##      캐시를 안 버린 채 나무가 그대로 남는다** — 그 구멍이 여기 말고는 안 보인다
##
## 헤드리스로 된다 — 창도 커서도 필요 없다.
## **어디를 보고 있는지는 묻지 않고 읽는다**: 커서가 없으니 방향은 엔진이 정한 대로고,
## 게이트는 그 방향에 나무가 오도록 **설 자리를 고른다.** 커서를 옮기는 게이트는
## 회차 8·9·10·11 을 잡아먹었다 (NUMBERS 10절).
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const WARMUP := 3          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다 (measure_collide 와 같다)
const BARE_SEC := 0.4      # 맨손으로 쥐고 있는 시간. 한 모션(0.24초)이 끝나고도 남는다
const AXE_SEC := 0.4       # 도끼를 들고 쥐고 있는 시간. 같은 이유로 한 모션보다 길다
const SEARCH := 40         # 스폰에서 이만큼(체비쇼프) 안에서 나무를 찾는다

var _main: Node
var _player: Node2D
var _tree := Vector2i.ZERO
var _stand := Vector2i.ZERO
var _facing := Vector2.RIGHT
var _frames := 0
var _t := 0.0
var _stage := 0            # 0 = 맨손 · 1 = 도끼
var _bare_frames := 0      # 맨손으로 **휘두른** 프레임 수
var _fills_before := 0
var _done := false

func tag() -> String:
	return "CHOP"

func begin(t: SceneTree) -> void:
	super(t)
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	tree.root.add_child(_main)

func cleanup() -> void:
	super()
	if _main != null:
		Input.action_release(_main.USE_ACTION)
	drop(_main)
	_main = null
	_player = null

func step(delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	if _done:
		return true
	_t += delta
	if _stage == 0:
		if _player.swing.is_swinging():
			_bare_frames += 1
		if _t < BARE_SEC:
			return false
		return _end_bare()
	if _t < AXE_SEC:
		return false
	return _finish()

## 설 자리를 고르고 **맨손으로** 쥐기 시작한다.
func _setup() -> bool:
	_player = _main.get_node_or_null("Player")
	if _player == null:
		fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _stop()
	if not _player.solid.is_valid():
		fail("배선", "player.solid 가 비어 있다 — main.gd 가 월드를 안 꽂았다", "WorldState.solid()")
		return _stop()
	_facing = _player.facing
	if not _find_tree():
		return _stop()
	_player.position = PlayerMotion.tile_center(_stand.x, _stand.y)
	_player.velocity = Vector2.ZERO
	# **맨손이다.** 핫바는 빈 채로 시작하므로 고른 칸을 그대로 둔다 — 빈 칸 = 맨손.
	if not _main.hotbar.is_empty_handed():
		fail("맨손", "핫바 %d번 칸에 %s 가 들려 있다" % [
			_main.hotbar.selected + 1, _main.hotbar.held_id()], "빈 칸(맨손)")
		return _stop()
	print("CHOP 나무 월드칸 %s · 설 자리 %s · 보는 쪽 %s · 스폰에서 %.1f칸" % [
		_tree, _stand, _facing, Vector2(_tree - WorldGen.spawn_tile()).length()])
	Input.action_press(_main.USE_ACTION)
	return false

## ① 맨손으로 400ms 쥐고 있었다 — **휘두르기는 했고 나무는 그대로**여야 한다.
func _end_bare() -> bool:
	Input.action_release(_main.USE_ACTION)
	var kind: int = _main.world.object_at(_tree.x, _tree.y)
	var ok := true
	if _bare_frames == 0:
		# 클릭이 아예 안 갔다. 여기서 안 잡으면 아래 판정이 **공허한 대조군**이 된다.
		ok = false
		fail("맨손 좌클릭", "%.2f초 동안 휘두른 프레임 0" % _t, "한 프레임 이상")
	if kind != WorldObjects.TREE:
		ok = false
		fail("맨손 벌목", "나무가 종류 %d 가 됐다" % kind, "나무(%d) 그대로" % WorldObjects.TREE)
	if _main.world.drop_count() != 0:
		ok = false
		fail("맨손 산출", "바닥에 %d 더미" % _main.world.drop_count(), "0 더미")
	if not ok:
		bad += 1
	print("CHOP 맨손      %.2f초 · 휘두른 프레임 %d · 나무 %s · 바닥 %d 더미  %s" % [
		_t, _bare_frames, "그대로" if kind == WorldObjects.TREE else "없어졌다",
		_main.world.drop_count(), "ok" if ok else "FAIL"])
	# ② 이제 도끼를 들려 준다. 손에 든 것 말고는 **아무것도 안 바꾼다.**
	_main.hotbar.items.add(Harvest.AXE, 1)
	_main.hotbar.select(0)
	_fills_before = _main.cache_fills
	_stage = 1
	_t = 0.0
	Input.action_press(_main.USE_ACTION)
	return false

func _finish() -> bool:
	Input.action_release(_main.USE_ACTION)
	var world = _main.world
	var kind: int = world.object_at(_tree.x, _tree.y)
	var blocked: bool = _player.solid.call(_tree.x, _tree.y)
	var drops: int = world.drop_count()
	var wood: int = world.dropped_total(Harvest.WOOD)
	var fills: int = _main.cache_fills - _fills_before
	var ok := true

	# ② 나무가 없어졌다.
	if kind != WorldObjects.NONE:
		ok = false
		fail("벌목", "%s 에 아직 종류 %d 가 있다" % [_tree, kind], "빈 칸(%d)" % WorldObjects.NONE)
	# ③ 벤 칸으로 걸어 들어갈 수 있다.
	if blocked:
		ok = false
		fail("벤 칸", "아직 막는다", "안 막는다 (걸어 들어갈 수 있다)")
	# ④ 목재가 그 칸 한가운데 떨어졌다. **개수는 규칙이 정한 그대로다.**
	var want := Harvest.drop_amount(WorldObjects.TREE)
	if drops != 1 or wood != want:
		ok = false
		fail("바닥의 목재", "%d 더미 · %d 개" % [drops, wood], "1 더미 · %d 개" % want)
	elif world.drops[0]["pos"] != PlayerMotion.tile_center(_tree.x, _tree.y):
		ok = false
		fail("떨어진 자리", "%s" % world.drops[0]["pos"],
			"%s (벤 칸 한가운데)" % PlayerMotion.tile_center(_tree.x, _tree.y))
	# ⑤ 화면을 다시 칠했다 — 제자리에 선 채로 벴는데 캐시를 안 버리면 0 이다.
	if fills < 1:
		ok = false
		fail("화면 다시 칠하기", "벤 뒤 색 캐시 %d번" % fills,
			"1번 이상 (안 버리면 벤 자리에 나무가 남는다)")
	if not ok:
		bad += 1
	print("CHOP 도끼      %.2f초 · 벤 칸 %s · 막힘 %s · 바닥 %d 더미 %d개 · 다시 칠하기 %d번  %s" % [
		_t, "빔" if kind == WorldObjects.NONE else "종류 %d" % kind,
		"예" if blocked else "아니오", drops, wood, fills, "ok" if ok else "FAIL"])
	print("CHOP %s (없어진 칸 %d · 사거리 %.0f px · 한 칸 %.0f px · 목재 %d개/그루)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad,
		world.cleared_count(), HandSwing.REACH, PlayerMotion.TILE, want])
	_done = true
	return true

## 게이트가 죽을 때도 **제 요약 줄을 남긴다** — 침묵은 초록으로 읽히면 안 된다.
func _stop() -> bool:
	bad += 1
	print("CHOP FAIL %d개 (설 자리를 못 잡았다)" % bad)
	_done = true
	return true

## 보고 있는 쪽에 **나무**가 오도록 설 자리를 고른다.
## 스폰에서 가까운 것부터 — 사람이 처음 만나는 나무가 그쪽이다.
## **설 자리는 빈 땅이어야 한다**: 막는 칸 위에 서면 그 자체가 다른 게이트의 일이 된다.
func _find_tree() -> bool:
	var world = _main.world
	var d := Vector2i(roundi(_facing.x), roundi(_facing.y))
	var sp := WorldGen.spawn_tile()
	for r in range(1, SEARCH):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var stand := Vector2i(sp.x + dx, sp.y + dy)
				if world.object_at(stand.x, stand.y) != WorldObjects.NONE:
					continue
				if _player.solid.call(stand.x, stand.y):
					continue
				var t := stand + d
				if world.object_at(t.x, t.y) != WorldObjects.TREE:
					continue
				_stand = stand
				_tree = t
				return true
	fail("나무", "스폰 %d칸 안에 %s 쪽으로 벨 나무가 없다 (씨앗 %d)" % [
		SEARCH, d, _main.WORLD_SEED], "한 그루 이상")
	return false
