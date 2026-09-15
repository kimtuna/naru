extends MeasurePhase

## **실측 게이트 — 다시 자란다** (GDD A-4 「한 번 캐고 끝나는 자원이 없다」).
## 진짜 메인 씬을 돌려 **시계가 흐르는지**부터 본다.
##
## 왜 단위 검사로 부족한가: `WorldState.tick()` 이 아무리 맞아도 **main.gd 가 그걸 안
## 부르면** 시간이 영영 0 초라 섬은 그루터기밭으로 남는다 — 그런데 단위 검사는 전부
## 초록이다. 회차 3(속도) · 5(방향) · 24(배치) · 29(벌목)와 같은 모양의 구멍이다.
##
## **여섯을 본다** (⑤⑥ 은 회차 32 가 얹었다):
##   ① **시계가 프레임을 따라 흐른다** — `world.now` 가 실제로 흐른 초와 맞는다.
##      main.gd 가 `tick` 을 안 부르면 0 이고, 엉뚱한 값을 넣으면 여기서 어긋난다
##   ② **몸이 선 칸은 안 자란다** — 벤 자리에 서서 하루를 넘겨도 그루터기다.
##      이게 없으면 나무가 사람 안에서 자라서 **몸이 낀다** (회차 29 가 막은 그것의 반대편)
##   ③ 비키면 자란다 — 칸이 나무로 돌아오고 **다시 막는다.** 막는 쪽은 미리 꽂아 둔
##      `player.solid` 라, 자란 것이 그 Callable 에 안 보이면 나무를 통과해 걷는다
##   ④ **화면을 다시 칠했다**(`cache_fills`) — 헤드리스라 픽셀은 못 읽지만, 색 캐시는
##      「보이는 범위가 바뀔 때만」 채우므로 **제자리에 선 채로는 그루터기가 그대로 남는다**
##   ⑤ **차지 목록의 계약** — `Claim.KINDS` 에 선언한 종류를 진짜 씬이 **전부 꽂았나**
##      (`claim.missing()` 이 비었나), 그리고 월드가 묻는 것이 **그 목록인가.**
##      P3 제작대·P4 밭을 만드는 회차가 등록을 빼먹으면 **그 회차 안에서** 여기가 빨갛다 —
##      단위 검사는 제 Callable 을 손으로 꽂으므로 그때도 전부 초록이다
##   ⑥ **설치물이 선 칸은 안 자란다** — 진짜 설치물은 아직 없으므로 **가짜 한 칸**을
##      살아 있는 `claim` 에 꽂고 날을 넘긴다. 임자의 **이름까지** 본다: 「안 자랐다」만
##      보면 몸이 막은 것과 구별이 안 돼서, 새 출처를 안 물어도 초록이다.
##      허물면 `RETRY_SEC` 안에 자란다 — 집을 헐면 그 자리에 숲이 돌아와야 한다
##
## **하루를 진짜로 기다리지 않는다**: 20분짜리 게이트는 루프를 죽인다. `tick()` 에
## 큰 `delta` 를 한 번 넣는다 — 세이브를 불러오는 자리와 **같은 입구**고, 판정을 무르게
## 하는 게 아니라 시계를 빨리 감는 것이다. ① 이 「진짜 프레임에서도 흐르나」를 따로 지킨다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const WARMUP := 3          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다 (measure_chop 과 같다)
const CLOCK_SEC := 0.30    # 시계를 견주는 구간. 30 프레임쯤 돈다

## 허용 오차. **이 게이트가 막는 것은 「main.gd 가 tick 을 안 부르거나 엉뚱한 델타를
## 넣는다」**이고, 안 부르면 오차는 구간 전체(0.30 = 100%)다.
##
## **0.01(3%) 까지 조일 수 있는 것은 구간이 프레임에 딱 맞기 때문이다** (회차 35).
## 재는 쪽과 재이는 쪽이 **같은 프레임 묶음**을 더하므로 남는 것은 부동소수 찌꺼기뿐이다
## (실측 0.000000 — 아래 `step` 의 주석이 그 등식이다). 회차 30~34 는 묶음이
## **한 프레임 어긋나** 있어서 0.008~0.105 가 랜덤하게 났고, 그걸 허용치로 덮으려다
## 0.05 → 0.10 으로 두 번 키웠다 — **허용치는 흔들림의 원인이 아니었다.**
##
## 막으려는 고장과의 여유: **안 부른다 30배**(0.30/0.01) · **델타를 10% 깎는다 3배**
## (0.03/0.01 — 옛 0.10 은 이걸 통째로 놓쳤다) · 부동소수 찌꺼기의 1e10 배.
## (회차 11 의 FACE · 회차 26 의 USE 와 같은 자리다: 시간을 프레임으로 재지 마라.)
const CLOCK_EPS := 0.01
const SETTLE := 3          # 몸을 옮기고 화면이 한 번 자리를 잡을 때까지
const READ := 2            # `_draw` 는 `_process` 뒤에 돈다 — 칠한 횟수는 다음 프레임에 읽는다
const SEARCH := 40         # 스폰에서 이만큼(체비쇼프) 안에서 나무를 찾는다
## 가짜 설치물의 이름. `Claim.KINDS` 밖의 이름이다 — 검사가 꽂는 것을 선언에 섞으면
## **아무도 안 꽂아도 `missing()` 이 비는** 구멍이 열린다 (⑤ 가 통째로 무너진다).
const FAKE := &"가짜 설치물(REGROW 게이트)"

var _main: Node
var _player: Node2D
var _tree := Vector2i.ZERO
var _stand := Vector2i.ZERO
var _frames := 0
var _stage := 0            # 0 = 시계 · 1 = 비켜서 자리잡기 · 2 = 읽기
var _wait := 0
var _t := 0.0              # 실제로 흐른 초 (프레임 delta 의 합)
var _now0 := 0.0           # 구간이 시작할 때의 게임 시계
var _game := 0.0           # 그 구간에 게임 시계가 흐른 초 — **찍는 줄이 이걸 봐야 한다**
var _drift := 0.0
var _held := false         # ② 몸이 선 채로 안 자랐나
var _held_by_thing := false   # ⑥ 설치물이 선 채로 안 자랐나
var _holder := &""            # ⑥ 그때 임자의 이름 — 몸이면 새 출처를 안 물은 것이다
var _freed := false           # ⑥ 허문 뒤 자랐나
var _fills_before := 0
var _done := false

func tag() -> String:
	return "REGROW"

func begin(t: SceneTree) -> void:
	super(t)
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	tree.root.add_child(_main)

func cleanup() -> void:
	super()
	drop(_main)
	_main = null
	_player = null

## **구간의 경계는 프레임에 딱 맞아야 한다** (회차 35).
##
## `SceneTree` 를 물려받은 스크립트의 `_process` 는 **노드의 `_process` 보다 먼저** 돈다
## (Godot 의 `SceneTree::process` 가 `MainLoop::process` 를 맨 앞에서 부른다). 그래서
## 프레임 n 에서 여기가 읽는 `world.now` 에는 **frame n 의 tick 이 아직 안 들어 있다**:
##
##   프레임 k 에서 읽은 now  = Σ delta[1 .. k-1]
##   프레임 E 에서 읽은 now  = Σ delta[1 .. E-1]
##   ⇒ 게임이 흐른 초        = Σ delta[k .. E-1]      ← 재이는 쪽
##
## 그러니 **우리도 delta[k .. E-1] 을 더해야 한다** — k(=WARMUP, `_setup` 이 도는
## 프레임)의 델타를 넣고, 끝 프레임 E 의 델타는 **넣기 전에** 끊는다.
## 회차 30~34 는 `delta[k+1 .. E]` 를 더했다: 한쪽에 delta[E], 다른 쪽에 delta[k] 가
## 남아 오차 = |delta[E] − delta[k]| 였다. 그런데 **k 는 이 판에서 가장 느린 프레임**이다
## (`_find_tree` 가 반지름 40 을 훑는다) — 그래서 0.008~0.105 가 판마다 다르게 났고,
## 「부하에서 흔들린다」로 보였다. 부하가 아니라 **등식이 틀려 있었다.**
func step(delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup(delta)
	if _done:
		return true
	match _stage:
		0:
			# **더하기 전에 끊는다** — 끝 프레임의 델타는 게임 시계에도 아직 안 들어갔다.
			if _t >= CLOCK_SEC:
				return _end_clock()
			_t += delta
			return false
		1:
			_wait -= 1
			if _wait > 0:
				return false
			return _let_it_grow()
		2:
			_wait -= 1
			if _wait > 0:
				return false
			return _read_regrow()
		_:
			return _installation()

func _setup(delta: float) -> bool:
	_player = _main.get_node_or_null("Player")
	if _player == null:
		fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _stop()
	if not _player.solid.is_valid():
		fail("배선", "player.solid 가 비어 있다 — main.gd 가 월드를 안 꽂았다", "WorldState.solid()")
		return _stop()
	if not _main.world.occupied.is_valid():
		fail("배선", "world.occupied 가 비어 있다 — 차지한 칸을 아무도 안 묻는다",
			"main.gd 가 꽂은 Callable")
		return _stop()
	if not _check_claim():
		return _stop("차지 목록이 계약을 어겼다")
	if not _find_tree():
		return _stop("설 자리를 못 잡았다")
	_player.position = PlayerMotion.tile_center(_stand.x, _stand.y)
	_player.velocity = Vector2.ZERO
	# **구간의 시작.** `now` 를 읽은 뒤 **이 프레임의 델타를 같이 넣는다** — 이 프레임의
	# tick 은 아래 노드 처리에서 돌아 `now` 쪽에 들어가므로, 우리 쪽에도 있어야 짝이 맞는다.
	_now0 = _main.world.now
	_t += delta
	print("REGROW 나무 월드칸 %s · 설 자리 %s · 하루 %.0f s · 나무 %.1f일" % [
		_tree, _stand, WorldState.DAY_SEC, WorldObjects.regrow_days(WorldObjects.TREE)])
	return false

## ⑤ **차지 목록의 계약.** 선언한 종류를 진짜 씬이 전부 꽂았고, 월드가 묻는 것이
## 바로 그 목록인가. 여기가 없으면 새 설치물을 만든 회차가 `Claim.KINDS` 에 이름만
## 적고 `add()` 를 빼먹어도 **아무 데도 안 터진다** — 반 년 뒤에 사람이
## 「자고 일어났더니 집 안에 나무가 섰다」로 겪는다.
func _check_claim() -> bool:
	var claim = _main.get("claim")
	if claim == null:
		fail("차지 목록", "main.gd 에 claim 이 없다", "Claim 하나")
		return false
	var missing: Array = claim.missing()
	if not missing.is_empty():
		fail("차지 목록", "선언만 하고 안 꽂은 종류 %s" % str(missing),
			"없다 (Claim.KINDS 의 %d 종을 전부 add 한다)" % Claim.KINDS.size())
		return false
	# **월드가 묻는 것이 그 목록인가.** 목록은 멀쩡한데 main.gd 가 몸 하나를 바로
	# 꽂아 두면 `missing()` 은 비어 있고 검사는 초록인데 **설치물은 안 물어진다.**
	if _main.world.occupied.get_object() != claim:
		fail("차지 목록", "world.occupied 가 claim 을 안 거친다 (%s)" % [
			_main.world.occupied.get_method()],
			"claim.covers — 출처가 하나든 넷이든 월드는 목록에 묻는다")
		return false
	print("REGROW 차지 출처  %d 종 %s · 선언 %d 종 · 안 꽂힌 것 없다" % [
		claim.count(), str(claim.names()), Claim.KINDS.size()])
	return true

## ① 시계가 프레임을 따라 흘렀나. 그리고 ② **벤 자리에 올라서서** 하루를 넘겨 본다.
func _end_clock() -> bool:
	var world = _main.world
	# **여기서 재 두지 않으면 못 잰다** — 바로 아래에서 하루를 감으므로 `world.now` 는
	# 곧 1200 초를 뛴다. 회차 30~34 의 찍는 줄은 그 뛴 값을 「게임 1202.58초」로
	# 보여 주고 있었다 — 오차만 맞고 **견준 두 값이 안 보였다.**
	_game = world.now - _now0
	_drift = absf(_game - _t)
	if _drift > CLOCK_EPS:
		fail("게임 시계", "%.3f초 도는 동안 %.3f초 흘렀다 (오차 %.4f)" % [
			_t, _game, _drift],
			"흐른 시간과 %.2f초 안에서 같다 (main.gd 가 tick 을 부른다)" % CLOCK_EPS)
	# ② 나무를 없애고 **그 자리에 올라선다.**
	if world.clear_object(_tree.x, _tree.y) != WorldObjects.TREE:
		fail("없애기", "%s 가 나무가 아니었다" % _tree, "나무(%d)" % WorldObjects.TREE)
		return _stop()
	_player.position = PlayerMotion.tile_center(_tree.x, _tree.y)
	_player.velocity = Vector2.ZERO
	var day := WorldState.DAY_SEC * WorldObjects.regrow_days(WorldObjects.TREE)
	world.tick(day + 1.0)
	_held = world.object_at(_tree.x, _tree.y) == WorldObjects.NONE
	if not _held:
		fail("몸이 선 칸", "벤 자리에 서 있는데 하루 만에 자랐다", "안 자란다 (몸이 낀다)")
	# ③ 비킨다. 화면이 자리를 잡고 나서 칠한 횟수를 잰다.
	_player.position = PlayerMotion.tile_center(_stand.x, _stand.y)
	_player.velocity = Vector2.ZERO
	_stage = 1
	_wait = SETTLE
	return false

## ③ 비켰다. `RETRY_SEC` 을 넘기면 자라야 한다.
func _let_it_grow() -> bool:
	_fills_before = _main.cache_fills
	_main.world.tick(WorldState.RETRY_SEC + 0.1)
	_stage = 2
	_wait = READ
	return false

## ②③④ 를 읽는다. **요약 줄은 아직 안 찍는다** — ⑥ 이 남았고, 「REGROW ok」가
## 두 번 나오면 `check.sh` 의 grep 이 첫 줄만 보고 초록으로 읽는다.
func _read_regrow() -> bool:
	var world = _main.world
	var kind: int = world.object_at(_tree.x, _tree.y)
	var blocked: bool = _player.solid.call(_tree.x, _tree.y)
	var fills: int = _main.cache_fills - _fills_before
	var ok := bad == 0

	if kind != WorldObjects.TREE:
		ok = false
		fail("다시 자라기", "%s 가 종류 %d 다" % [_tree, kind], "나무(%d)" % WorldObjects.TREE)
	if not blocked:
		ok = false
		fail("자란 칸", "안 막는다", "막는다 (나무를 통과해 걸으면 안 된다)")
	if world.cleared_count() != 0:
		ok = false
		fail("없어진 칸의 수", "%d" % world.cleared_count(), "0 (목록에서 지워진다)")
	if fills < 1:
		ok = false
		fail("화면 다시 칠하기", "자란 뒤 색 캐시 %d번" % fills,
			"1번 이상 (안 버리면 화면에 그루터기가 남는다)")
	if not ok:
		bad += 1
	print("REGROW 시계      %.3f초 도는 동안 게임 %.3f초 (오차 %.6f초 · 허용 %.2f)" % [
		_t, _game, _drift, CLOCK_EPS])
	print("REGROW 몸이 선 칸 하루+1초 뒤 %s · 비킨 뒤 %s · 막힘 %s · 다시 칠하기 %d번" % [
		"그대로" if _held else "자랐다", "나무" if kind == WorldObjects.TREE else "종류 %d" % kind,
		"예" if blocked else "아니오", fills])
	_stage = 3
	return false

## ⑥ **설치물이 선 칸은 안 자란다** (GDD A-4 · 회차 32). 살아 있는 `claim` 에 가짜
## 설치물 한 칸을 꽂고 날을 넘긴다 — 몸은 비켜 서 있으므로, 그래도 안 자랐다면
## **새로 꽂은 출처를 월드가 실제로 물었다는 뜻**이다. 임자의 이름으로 한 번 더 못을 박는다.
func _installation() -> bool:
	var world = _main.world
	var claim = _main.claim
	var standing := [true]     # 람다는 값을 복사해 간다 (GOTCHAS)
	if not claim.add(FAKE, func(tile: Vector2i) -> bool: return standing[0] and tile == _tree):
		fail("가짜 설치물", "claim.add 가 거절했다", "꽂힌다")
		return _summary(world, claim)
	if world.clear_object(_tree.x, _tree.y) != WorldObjects.TREE:
		fail("없애기", "%s 가 나무가 아니었다" % _tree, "나무(%d)" % WorldObjects.TREE)
		return _summary(world, claim)
	var day := WorldState.DAY_SEC * WorldObjects.regrow_days(WorldObjects.TREE)
	world.tick(day + 1.0)
	_held_by_thing = world.object_at(_tree.x, _tree.y) == WorldObjects.NONE
	_holder = claim.holder(_tree)
	if not _held_by_thing:
		fail("설치물이 선 칸", "설치물 아래에서 하루 만에 자랐다",
			"안 자란다 (집 거실에 나무가 선다)")
	if _holder != FAKE:
		fail("임자", "%s" % ["아무도 없다" if _holder == &"" else _holder],
			"%s (새로 꽂은 출처를 안 묻는다)" % FAKE)
	# **허물면 자란다.** 「영영 안 자라는 칸」으로 적어 두면 되돌릴 자리가 없어진다.
	standing[0] = false
	world.tick(WorldState.RETRY_SEC + 0.1)
	_freed = world.object_at(_tree.x, _tree.y) == WorldObjects.TREE
	if not _freed:
		fail("허문 자리", "설치물을 치웠는데 %.1f초 뒤에도 안 자랐다" % WorldState.RETRY_SEC,
			"나무로 돌아온다")
	print("REGROW 설치물     하루+1초 뒤 %s (임자 %s) · 허문 뒤 %s" % [
		"그대로" if _held_by_thing else "자랐다",
		"없다" if _holder == &"" else _holder,
		"나무" if _freed else "그루터기"])
	return _summary(world, claim)

## **게이트의 마지막 한 줄.** `check.sh` 가 보는 것이 이 줄이다 — 죽는 길에서도 찍는다.
func _summary(world, claim) -> bool:
	if bad == 0 and not (_held and _held_by_thing and _freed):
		bad += 1
	print("REGROW %s (하루 %.0f s · 나무 %.1f일 · 비킨 뒤 %.1f s · 남은 벤 칸 %d · 차지 출처 %d 종)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, WorldState.DAY_SEC,
		WorldObjects.regrow_days(WorldObjects.TREE), WorldState.RETRY_SEC,
		world.cleared_count(), claim.count()])
	_done = true
	return true

## 게이트가 죽을 때도 **제 요약 줄을 남긴다** — 침묵은 초록으로 읽히면 안 된다.
## **왜 죽었는지를 그 줄에 적는다**: 배선이 틀려도 「설 자리를 못 잡았다」가 뜨면
## 다음 사람이 나무부터 찾으러 간다 (회차 32 가 제 대조군에서 겪었다).
func _stop(why := "세우다 죽었다") -> bool:
	bad += 1
	print("REGROW FAIL %d개 (%s)" % [bad, why])
	_done = true
	return true

## **옆 칸이 나무인 빈 땅**을 고른다. 벤 뒤에 그 칸으로 올라서야 하므로 둘 다 필요하다.
## 스폰에서 가까운 것부터 — CHOP 과 같은 자리를 고르지만 방향은 안 본다 (클릭을 안 쓴다).
func _find_tree() -> bool:
	var world = _main.world
	var sp := WorldGen.spawn_tile()
	for r in range(1, SEARCH):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var stand := Vector2i(sp.x + dx, sp.y + dy)
				if _player.solid.call(stand.x, stand.y):
					continue
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var t := stand + d
					if world.object_at(t.x, t.y) != WorldObjects.TREE:
						continue
					_stand = stand
					_tree = t
					return true
	fail("나무", "스폰 %d칸 안에 빈 땅과 맞붙은 나무가 없다 (씨앗 %d)" % [
		SEARCH, _main.WORLD_SEED], "한 그루 이상")
	return false
