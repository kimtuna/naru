extends SceneTree

## **실측 게이트 — 이동 충돌.** 진짜 메인 씬을 물리로 돌려
## **진짜 섬의 해안**에 걸어서 부딪힌다. 손으로 만든 지도가 아니다.
##
## 왜 단위 검사로 부족한가: `WorldCollide` 가 아무리 맞아도
## **노드가 그걸 안 부르거나 main.gd 가 월드를 안 꽂으면** 플레이어는 바다 위를 걸어간다 —
## 그런데 단위 검사는 전부 초록으로 남는다.
## (바퀴 3 의 속도, 4 의 화면, 5 의 방향과 같은 모양의 구멍이다. NUMBERS 5절)
##
## **메인 씬을 통째로 띄우는 것이 핵심이다.** 플레이어 씬만 띄우면 배선이 안 잡힌다.
##
## 헤드리스로 된다 — 창도 커서도 필요 없다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const RUN := 7             # 세로로 이만큼 곧은 해안을 찾는다 (미끄러지는 동안 옆이 계속 바다여야 한다)
const RUNWAY := 3          # 해안 서쪽으로 이만큼 땅이 있어야 뛰어들 거리가 나온다
const STRAIGHT := 1.0      # 바다로 곧장 걷는 시간(초). 240px = 5칸이라 활주로를 넘는다
const SLIDE := 1.2         # 해안을 타는 시간(초). 대각 한 축 169.71 × 1.2 = 203.6px 라 활주로를 넘는다
const TOL_POS := 0.05      # 벽에 붙는 자리는 계산이 정한다 — 틱 경계가 안 섞인다
const TOL_RATE := 5.0      # 속력은 물리 틱 경계로 ±1틱(4px) 이 남는다 (measure_move 와 같다)
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
var _bad := 0
var _frames := 0

func _initialize() -> void:
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	root.add_child(_main)

## 배선은 씬의 _ready 가 한다 — **_initialize 에서 보면 아직 비어 있다.**
func _setup() -> bool:
	_player = _main.get_node_or_null("Player")
	if _player == null:
		_fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return _finish()
	if not _player.solid.is_valid():
		# **배선이 끊긴 것이다.** 여기서 안 잡으면 아래 구간이 「바다를 통과」로 나온다.
		_fail("배선", "player.solid 가 비어 있다 — main.gd 가 월드를 안 꽂았다",
			"WorldCollide.solid_from_seed")
		return _finish()
	if not _find_coast():
		return _finish()
	_phases = [
		{"name": "바다로 직진", "keys": ["move_right"], "sec": STRAIGHT, "rate_y": 0.0},
		{"name": "해안 미끄럼", "keys": ["move_right", "move_down"], "sec": SLIDE,
			"rate_y": PlayerMotion.SPEED / sqrt(2.0)},
	]
	_start_phase()
	return false

## 곧은 남북 해안을 찾는다: 땅 %d칸 × 활주로 옆으로, 그 오른쪽은 전부 바다.
## 스폰에서 가장 가까운 것을 고른다 — 플레이어가 실제로 처음 만나는 해안이다.
func _find_coast() -> bool:
	var world_seed: int = _main.WORLD_SEED
	var grid := WorldGen.generate(world_seed)
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
					if WorldGen.at(grid, tx - j, ty + k) != WorldGen.LAND:
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
		_fail("해안", "씨앗 %d 에 곧은 해안(땅 %d×%d + 바다)이 없다" % [world_seed, RUNWAY + 1, RUN],
			"한 군데 이상")
		return false
	_start = _main.screen_of(Vector2i(_coast.x - RUNWAY, _coast.y))
	_wall = _main.screen_of(Vector2i(_coast.x + 1, _coast.y)).x - PlayerMotion.TILE * 0.5
	print("COLLIDE 해안 월드칸 %s · 스폰에서 %.1f칸 · 활주로 %d칸 · 바다 면 %.2f px" % [
		_coast, best, RUNWAY, _wall])
	return true

func _start_phase() -> void:
	_t = 0.0
	_player.position = _start
	_player.velocity = Vector2.ZERO
	_from = _start
	for k in _phases[_i]["keys"]:
		Input.action_press(k)

func _process(delta: float) -> bool:
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
	var want_x := _wall - WorldCollide.HALF - WorldCollide.EPS
	var rate_y := moved.y / _t
	var ok := true

	# ① 바다 앞에 선다. 지나갔으면 이 판정이 통째로 무너진다.
	if absf(pos.x - want_x) > TOL_POS:
		ok = false
		_fail("%s 멈춘 자리" % p["name"], "%.2f px" % pos.x, "%.2f px" % want_x)
	# ② 몸이 바다에 걸치지 않는다. 벽 앞 좌표가 맞아도 반 칸 잠겼으면 그림이 틀린다.
	if WorldCollide.overlaps(pos, _player.solid):
		ok = false
		_fail("%s 몸이 바다에" % p["name"], "겹침 %s" % pos, "안 겹침")
	# ③ 옆으로 가려던 몫은 살아 있다 — 이게 「미끄러진다」다.
	if absf(rate_y - p["rate_y"]) > TOL_RATE:
		ok = false
		_fail("%s 세로 속력" % p["name"], "%.2f px/s" % rate_y, "%.2f ±%.0f px/s" % [p["rate_y"], TOL_RATE])

	if not ok:
		_bad += 1
	print("COLLIDE %-12s x %8.2f (바다 면 %.2f) · 세로 %7.2f px/s · %.4f s 동안 %s  %s" % [
		p["name"], pos.x, _wall, rate_y, _t, moved, "ok" if ok else "FAIL"])

## 「이 칸이 막나」 한 번의 값. 지금은 물을 때마다 잡음을 다시 푼다 —
## 한 물리 틱에 네 번쯤 묻는다(옆축 2줄 × 두 축). 이 값이 커지면 월드를 미리 구워 둔다.
func _query_cost() -> void:
	if not _player.solid.is_valid():
		return
	var n := 100000
	var off: Vector2i = _main.tile_offset      # 월드 칸을 화면 칸으로 되돌려 묻는다
	var t0 := Time.get_ticks_usec()
	var hit := 0
	for i in n:
		if _player.solid.call(i % WorldGen.SIZE - off.x, (i / WorldGen.SIZE) % WorldGen.SIZE - off.y):
			hit += 1
	var us := Time.get_ticks_usec() - t0
	print("COLLIDE 질의 %d회 %.1f ms (1회 %.3f µs · 막힘 %.1f%%)" % [
		n, us / 1000.0, float(us) / n, 100.0 * hit / n])

func _finish() -> bool:
	_query_cost()
	print("COLLIDE %s (구간 %d · 몸 반폭 %.0f · 틈 %.2f · 물리 %d Hz)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, _phases.size(),
		WorldCollide.HALF, WorldCollide.EPS, Engine.physics_ticks_per_second])
	quit(1 if _bad > 0 else 0)
	return true

func _fail(what: String, actual: String, expected: String) -> void:
	_bad += 1
	print("COLLIDE FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])
