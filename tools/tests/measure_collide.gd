extends MeasurePhase

## **실측 게이트 — 이동 충돌.** 진짜 메인 씬을 물리로 돌려
## **진짜 섬의 해안**에 걸어서 부딪힌다. 손으로 만든 지도가 아니다.
##
## 왜 단위 검사로 부족한가: `WorldCollide` 가 아무리 맞아도
## **노드가 그걸 안 부르거나 main.gd 가 월드를 안 꽂으면** 플레이어는 바다 위를 걸어간다 —
## 그런데 단위 검사는 전부 초록으로 남는다.
## (회차 3 의 속도, 4 의 화면, 5 의 방향과 같은 모양의 구멍이다. NUMBERS 5절)
##
## **메인 씬을 통째로 띄우는 것이 핵심이다.** 플레이어 씬만 띄우면 배선이 안 잡힌다.
##
## 헤드리스로 된다 — 창도 커서도 필요 없다.
##
## **홀로 도는 프로세스가 아니다** (회차 27): `measure_headless.gd` 의 한 구간이다.
## `_initialize`/`_process` 가 `begin`/`step` 이 됐고 **`_frames` 는 구간마다 0 에서
## 다시 센다** — `WARMUP` 은 여전히 「이 씬이 선 뒤 몇 프레임」이다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const RUN := 7             # 세로로 이만큼 곧은 해안을 찾는다 (미끄러지는 동안 옆이 계속 바다여야 한다)
const RUNWAY := 3          # 해안 서쪽으로 이만큼 땅이 있어야 뛰어들 거리가 나온다
const STRAIGHT := 1.0      # 바다로 곧장 걷는 시간(초). 240px = 15칸이라 활주로(49.99px)를 넘는다
# 해안을 타는 **몫**. 초가 아니다 — `_slide_sec()` 가 기하에서 푼다.
#
# **초로 적었다가 두 회차를 잡아먹었다**: 1.2 → 0.9 (회차 15, 타일 32) 로 손으로 줄였는데
# 타일이 또 반이 되면서 0.9 는 다시 틀린 값이 됐다 (대각 한 축 169.71 × 0.9 = 152.7px 라
# 곧은 해안 7줄 = 112px 를 넘쳐 미끄럼이 해안 밖에서 끝난다).
# **그 상수는 처음부터 「해안 몇 줄」이었다** — 그래서 이제 줄에서 시간을 푼다.
# 남은 0.2 는 물리 틱 경계(한 틱 2.8px)와 해안이 딱 RUN 줄일 때의 여유다.
const SLIDE_FILL := 0.8
## 벽에 붙는 자리는 계산이 정한다 — 틱 경계가 안 섞인다. **잰 폭 0.000** (9판).
## 막는 고장은 **물리 한 틱에 가는 4px(=240/60) 만큼 지나침** — 여유 **80배**.
const TOL_POS := 0.05
# **그리는 네모가 막힌 칸에 걸치는 몫의 상한(px).** 몸통이 1칸 폭(16)이고 상자 반폭이
# 6 이면 걸치는 것은 8 - 6 - 0.01 = **1.99px** 뿐이다 — 일부러 남긴 여유 그 자체다.
# **타일이 반이 돼도 1.99 는 그대로다**: `HALF` 의 2px 여유가 절대값이라 그렇다.
# 몸통이 1.5칸이던 회차 15 까지는 **10px** 였다: 좌표는 맞는데 사람 눈에는 벽에 파묻혔다.
## **잰 폭 0.000** (9판 전부 1.989990 — 상수에서 나오는 값이라 안 흔들린다).
## 막는 고장은 **몸이 반 칸(8px) 바다에 잠긴 그림** — 여유 **3.2배**.
const MAX_OVER := 2.5
## 속력의 허용치. **잡음보다 좁게 잡으면 안 된다.**
## 미끄럼 구간은 0.48초쯤이고 물리 한 틱(16.7ms)은 그 **3.5%** 다 — 속력으로 치면
## **±5.9 px/s**. 5.0 은 그 아래라 **언제든 터지는 값**이었다 (2026-09-15 실측
## 165.94 · 166.36 · 170.50 · 174.83 — 폭 9). 10.0 은 잡음을 덮으면서도,
## 이 판정이 막는 것(「벽에 닿으면 통째로 멈춘다」 → 세로 0)을 **17배 여유로** 잡는다.
## measure_move 의 ±5 는 구간이 1초라 틱 오차가 1.7% 뿐이어서 다르다.
## **9판으로 다시 쟀다** (2026-09-15 · `jitter.sh 9`): 최대 2.830 · 폭 1.052 —
## 회차 35 가 본 폭 9 보다 좁다. 여유 **17.0배**.
const TOL_RATE := 10.0
const WARMUP := 3          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다

var _main: Node
var _player: Node2D
var _coast := Vector2i.ZERO      # 해안의 **땅** 쪽 칸 (오른쪽이 바다)
var _wall := 0.0                 # 바다 칸의 왼쪽 면 (화면 px)
var _start := Vector2.ZERO
var _phases := []
var _i := 0
var _t := 0.0
var _from := Vector2.ZERO
var _frames := 0

func tag() -> String:
	return "COLLIDE"

func begin(t: SceneTree) -> void:
	super(t)
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	tree.root.add_child(_main)

## 메인 씬을 통째로 걷는다 — 두고 가면 다음 구간의 카메라와 둘이 된다.
func cleanup() -> void:
	super()
	drop(_main)
	_main = null
	_player = null

## 배선은 씬의 _ready 가 한다 — **_initialize 에서 보면 아직 비어 있다.**
func _setup() -> bool:
	_player = _main.get_node_or_null("Player")
	if _player == null:
		fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _finish()
	if not _player.solid.is_valid():
		# **배선이 끊긴 것이다.** 여기서 안 잡으면 아래 구간이 「바다를 통과」로 나온다.
		fail("배선", "player.solid 가 비어 있다 — main.gd 가 월드를 안 꽂았다",
			"WorldCollide.solid_from_seed")
		return _finish()
	if not _find_coast():
		return _finish()
	_phases = [
		{"name": "바다로 직진", "keys": ["move_right"], "sec": STRAIGHT, "rate_y": 0.0},
		{"name": "해안 미끄럼", "keys": ["move_right", "move_down"], "sec": _slide_sec(),
			"rate_y": PlayerMotion.SPEED / sqrt(2.0)},
	]
	_start_phase()
	return false

## 해안을 타는 시간(초). **곧은 해안 RUN 줄 안에서 끝나야 한다** — 넘치면 미끄럼이
## 해안 밖에서 끝나서 「벽 앞에 선 자리」가 딴 칸의 값이 된다.
## 시작은 첫 줄 한가운데(TILE × 0.5)이고 상자 아래끝이 HALF.y 만큼 더 내려가므로
## 내려갈 수 있는 거리는 `(RUN - 0.5) × TILE - HALF.y` 다. 그중 SLIDE_FILL 만 쓴다.
func _slide_sec() -> float:
	var room := (RUN - 0.5) * PlayerMotion.TILE - WorldCollide.HALF.y
	return room * SLIDE_FILL / (PlayerMotion.SPEED / sqrt(2.0))

## 곧은 남북 해안을 찾는다: 땅 %d칸 × 활주로 옆으로, 그 오른쪽은 전부 바다.
## 스폰에서 가장 가까운 것을 고른다 — 플레이어가 실제로 처음 만나는 해안이다.
##
## **활주로에 나무·돌이 없어야 한다** (회차 24). 전에는 「땅이면 걸을 수 있다」였고
## 그게 참이었다 — 월드가 빈 벌판이었기 때문이다. 이제 땅에도 막는 칸이 있으므로
## **게이트가 제 전제를 말로 적는다**: 안 적으면 활주로 한복판의 나무가
## 「해안 앞에 안 섰다」로 나타나서, 배치를 조금 만질 때마다 엉뚱한 게이트가 빨개진다.
func _find_coast() -> bool:
	var world_seed: int = _main.WORLD_SEED
	var grid := WorldGen.generate(world_seed)
	var objs := WorldObjects.generate(world_seed)
	var spawn := WorldGen.spawn_tile()
	var best := -1.0
	for ty in range(1, WorldGen.SIZE - RUN):
		for tx in range(RUNWAY + 1, WorldGen.SIZE - 1):
			var ok := true
			for k in RUN:
				if WorldGen.at(grid, tx + 1, ty + k) != WorldGen.WATER:
					ok = false
					break
				for j in RUNWAY + 1:
					if WorldGen.at(grid, tx - j, ty + k) != WorldGen.LAND \
							or WorldObjects.at_grid(objs, tx - j, ty + k) != WorldObjects.NONE:
						ok = false
						break
				if not ok:
					break
			if not ok:
				continue
			var d := Vector2(tx - spawn.x, ty - spawn.y).length()
			if best < 0.0 or d < best:
				best = d
				_coast = Vector2i(tx, ty)
	if best < 0.0:
		fail("해안", "씨앗 %d 에 곧은 해안(빈 땅 %d×%d + 바다)이 없다" % [world_seed, RUNWAY + 1, RUN],
			"한 군데 이상")
		return false
	# **화면 칸 = 월드 칸이다** (P1-6). 카메라가 오면서 main.gd 의 `tile_offset` 이 사라졌다.
	_start = PlayerMotion.tile_center(_coast.x - RUNWAY, _coast.y)
	_wall = float(_coast.x + 1) * PlayerMotion.TILE
	print("COLLIDE 해안 월드칸 %s · 스폰에서 %.1f칸 · 빈 활주로 %d칸 · 바다 면 %.2f px" % [
		_coast, best, RUNWAY, _wall])
	return true

func _start_phase() -> void:
	_t = 0.0
	_player.position = _start
	_player.velocity = Vector2.ZERO
	_from = _start
	for k in _phases[_i]["keys"]:
		Input.action_press(k)

func step(delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	_t += delta
	if _t < _phases[_i]["sec"]:
		return false
	for k in _phases[_i]["keys"]:
		Input.action_release(k)
	_check_phase()
	_i += 1
	if _i < _phases.size():
		_start_phase()
		return false
	return _finish()

func _check_phase() -> void:
	var p: Dictionary = _phases[_i]
	var pos: Vector2 = _player.position
	var moved := pos - _from
	var want_x := _wall - WorldCollide.HALF.x - WorldCollide.EPS
	var rate_y := moved.y / _t
	var ok := true

	# ① 바다 앞에 선다. 지나갔으면 이 판정이 통째로 무너진다.
	Tol.obs("COLLIDE.멈춘자리", "band", absf(pos.x - want_x), TOL_POS)
	if absf(pos.x - want_x) > TOL_POS:
		ok = false
		fail("%s 멈춘 자리" % p["name"], "%.2f px" % pos.x, "%.2f px" % want_x)
	# ② 몸이 바다에 걸치지 않는다. 벽 앞 좌표가 맞아도 반 칸 잠겼으면 그림이 틀린다.
	if WorldCollide.overlaps(pos, _player.solid):
		ok = false
		fail("%s 몸이 바다에" % p["name"], "겹침 %s" % pos, "안 겹침")
	# ③ 옆으로 가려던 몫은 살아 있다 — 이게 「미끄러진다」다.
	Tol.obs("COLLIDE.세로속력.%s" % p["name"], "band", absf(rate_y - p["rate_y"]), TOL_RATE)
	if absf(rate_y - p["rate_y"]) > TOL_RATE:
		ok = false
		fail("%s 세로 속력" % p["name"], "%.2f px/s" % rate_y, "%.2f ±%.0f px/s" % [p["rate_y"], TOL_RATE])
	# ④ **그리는 네모가 막힌 칸에 얼마나 걸치나** (회차 16). ①②③ 이 전부 맞아도
	#    네모가 상자보다 한참 넓으면 사람 눈에는 몸이 바다에 잠긴 채로 보인다 —
	#    단위 검사도 좌표 판정도 이 구멍을 못 본다. **살아 있는 씬의 네모를 읽는다.**
	var over := pos.x + _body_half_x() - _wall
	Tol.obs("COLLIDE.걸침", "cap", over, MAX_OVER)
	if over > MAX_OVER:
		ok = false
		fail("%s 네모가 바다에 걸침" % p["name"], "%.2f px" % over, "%.2f px 이하" % MAX_OVER)

	if not ok:
		bad += 1
	print("COLLIDE %-12s x %8.2f (바다 면 %.2f) · 세로 %7.2f px/s · 걸침 %.2f px · %.4f s 동안 %s  %s" % [
		p["name"], pos.x, _wall, rate_y, over, _t, moved, "ok" if ok else "FAIL"])

## 그리는 네모의 반폭. **씬에서 읽는다** — 상수로 적으면 씬을 넓혀도 안 따라온다.
## 네모가 없으면 0 을 준다: 그건 `test_player_scene.gd` 가 잡을 일이다.
func _body_half_x() -> float:
	if _player == null:
		return 0.0
	var body := _player.get_node_or_null("Body") as Control
	return body.size.x * 0.5 if body != null else 0.0

## 「이 칸이 막나」 한 번의 값. 지금은 물을 때마다 잡음을 다시 푼다 —
## 한 물리 틱에 네 번쯤 묻는다(옆축 2줄 × 두 축). 이 값이 커지면 월드를 미리 구워 둔다.
func _query_cost() -> void:
	# **한 프로세스가 된 뒤로 여기서 죽으면 뒤 구간이 통째로 안 돈다** (회차 27).
	# `_setup` 이 플레이어를 못 찾고 곧장 `_finish` 로 오는 길이 있다.
	if _player == null or not _player.solid.is_valid():
		return
	var n := 100000
	var t0 := Time.get_ticks_usec()
	var hit := 0
	for i in n:
		if _player.solid.call(i % WorldGen.SIZE, (i / WorldGen.SIZE) % WorldGen.SIZE):
			hit += 1
	var us := Time.get_ticks_usec() - t0
	print("COLLIDE 질의 %d회 %.1f ms (1회 %.3f µs · 막힘 %.1f%%)" % [
		n, us / 1000.0, float(us) / n, 100.0 * hit / n])

func _finish() -> bool:
	_query_cost()
	print("COLLIDE %s (구간 %d · 타일 %.0f · 미끄럼 %.3f s · 상자 반크기 %.0f x %.0f · 네모 반폭 %.0f · 틈 %.2f · 물리 %d Hz)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, _phases.size(),
		PlayerMotion.TILE, _slide_sec(),
		WorldCollide.HALF.x, WorldCollide.HALF.y, _body_half_x(),
		WorldCollide.EPS, Engine.physics_ticks_per_second])
	return true
