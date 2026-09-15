extends MeasurePhase

## **실측 게이트 — 낮과 밤** (GDD G-1b 하루 20분 = 낮 10 + 밤 10).
## 진짜 메인 씬을 돌려 **시계가 하늘빛으로 나오는지**를 본다.
##
## 왜 단위 검사로 부족한가: `DayCycle` 이 아무리 맞아도 `main.gd` 가 `Sky` 를 안
## 물들이면 섬은 **영영 한낮**인데 단위 검사는 전부 초록이다. 회차 3(속도) ·
## 5(방향) · 24(배치) · 29(벌목) · 30(시계)와 글자 그대로 같은 모양의 구멍이다.
##
## **픽셀은 여기서 안 본다** — 헤드리스는 렌더러가 더미라 뷰포트가 빈다 (NUMBERS 3b절).
## 구운 화면이 정말 어두워지는지는 `measure_window.gd` 의 DRAW `[밤]` 구간이 잰다.
## 둘은 짝이다: **여기는 배선, 저기는 픽셀.**
##
## **넷을 본다**:
##   ① `Sky` 가 **월드 캔버스에 있다** — 핫바와 같은 캔버스에 있으면 밤에 가방이
##      같이 어두워진다. RID 로 묻는다: 이름이나 부모가 아니라 **곱이 닿는 범위**가 규칙이다.
##      **`main.gd` 가 실제로 물들이는 노드를 집는다**(`_main.sky`), 경로로 찾지 않는다 —
##      경로로 찾으면 하늘을 옮기는 순간 「없다」로 죽어서 이 ① 이 영영 안 돈다
##   ② **하루 한 바퀴를 돌며** 매번 `Sky.color` 가 그 시각의 빛과 같다.
##      `_ready` 에서 한 번만 칠했으면 두 번째 표본에서 빨개진다
##   ③ 그 한 바퀴에 **한낮과 한밤이 둘 다 나온다** — 제일 밝은 표본은 흰색이고
##      제일 어두운 표본은 어둡다. 빛이 상수면 여기서 걸린다
##   ④ **시계를 안 건드리고 프레임만 돌려도** 빛이 계속 따라온다
##
## **시계를 손으로 옮긴다**: 하루를 진짜로 기다리면 20분짜리 게이트가 된다.
## 되감기도 하는데, 이 구간이 끝나면 씬을 통째로 버리므로 벤 칸의 줄서기에 안 샌다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const WARMUP := 3          # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다 (measure_regrow 와 같다)
const SAMPLES := 24        # 하루를 이만큼으로 쪼개 돈다. 1200초 / 24 = 50초 간격
const FOLLOW := 5          # ④ 시계를 놓아둔 채 도는 프레임
## 빛의 허용 오차. 한 프레임(delta) 만큼 뒤처져도 봐준다 — 여명 구간의 기울기가
## 하루의 0.08 에 걸쳐 0.7 이라 한 프레임은 1e-5 쯤이다. 낮과 밤의 차(0.7)의 1/70 이다.
const TOL := 0.01
const DAY_MIN := 0.99      # ③ 제일 밝은 표본은 이보다 밝다 (한낮은 곱이 1 이다)
const NIGHT_MAX := 0.5     # ③ 제일 어두운 표본은 이보다 어둡다

var _main: Node
var _sky: CanvasModulate
var _frames := 0
var _i := -1               # 지금 재는 표본 번호. -1 = 아직 안 셌다
var _worst := 0.0          # ② 가장 크게 어긋난 빛
var _worst_at := ""
var _bright := -1.0        # ③ 한 바퀴에서 제일 밝았던 값
var _bright_p := 0.0
var _dark := 2.0
var _dark_p := 0.0
var _days := 0             # 낮으로 세어진 표본 수
var _follow := 0
var _done := false

func tag() -> String:
	return "DAY"

func begin(t: SceneTree) -> void:
	super(t)
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	tree.root.add_child(_main)

func cleanup() -> void:
	super()
	drop(_main)
	_main = null
	_sky = null

func step(_delta: float) -> bool:
	_frames += 1
	if _frames < WARMUP:
		return false
	if _frames == WARMUP:
		return _setup()
	if _done:
		return true
	if _i < SAMPLES:
		return _sample()
	return _follow_clock()

## ① 하늘이 **월드 캔버스**에 있나.
func _setup() -> bool:
	_sky = _main.sky as CanvasModulate
	if _sky == null:
		fail("하늘", "main.gd 의 `sky` 가 비었거나 CanvasModulate 가 아니다",
			"메인 씬의 CanvasModulate (게임이 실제로 물들이는 그 노드)")
		return _stop()
	var bar := _main.get_node_or_null("UI/Hotbar") as CanvasItem
	if bar == null:
		fail("핫바", "Main/UI/Hotbar 가 없다", "핫바 (하늘이 안 닿을 캔버스의 증인)")
		return _stop()
	# **부모가 아니라 캔버스를 묻는다.** `CanvasModulate` 는 제가 속한 캔버스 전부를
	# 물들이므로, 「어디에 매달렸나」가 아니라 「어느 캔버스인가」가 규칙이다.
	if _sky.get_canvas() != (_main as CanvasItem).get_canvas():
		fail("하늘의 캔버스", "월드와 다른 캔버스에 있다", "월드와 같은 캔버스 (안 그러면 땅이 안 어두워진다)")
	if _sky.get_canvas() == bar.get_canvas():
		fail("하늘의 캔버스", "핫바와 같은 캔버스다", "핫바와 다른 캔버스 (밤에 가방이 같이 어두워진다)")
	print("DAY 하루 %.0f s · 표본 %d개 (%.0f s 간격) · 여명 %.0f s" % [
		WorldState.DAY_SEC, SAMPLES, WorldState.DAY_SEC / SAMPLES,
		DayCycle.TWILIGHT * WorldState.DAY_SEC])
	_i = 0
	return false

## ②③ 하루 한 바퀴. **한 표본에 한 프레임** — 시계를 옮기고 **다음** 프레임에 읽는다.
## main.gd 의 `_process` 가 그 사이에 한 번 돌아야 하늘이 새 시각을 안다.
## 그래서 마지막 표본은 이 바퀴가 아니라 `_follow_clock` 의 첫 프레임이 읽는다.
func _sample() -> bool:
	if _i > 0:
		_read(true)
	_main.world.now = WorldState.DAY_SEC * float(_i) / SAMPLES
	_i += 1
	return false

## `count` 는 **하루 한 바퀴의 표본인가**. 따라가기(④)의 읽기는 시각을 안 옮기므로
## 같은 자리를 여러 번 보는데, 그것까지 세면 「낮이 반이다」가 거짓이 된다.
func _read(count: bool) -> void:
	var now: float = _main.world.now
	var want := DayCycle.light_at(now)
	var got := _sky.color
	var d: float = maxf(maxf(absf(want.r - got.r), absf(want.g - got.g)), absf(want.b - got.b))
	if d > _worst:
		_worst = d
		_worst_at = "위상 %.3f · 잰 값 %s · 기대 %s" % [DayCycle.phase(now), got.to_html(false), want.to_html(false)]
	var lum := (got.r + got.g + got.b) / 3.0
	var p := DayCycle.phase(now)
	if lum > _bright:
		_bright = lum
		_bright_p = p
	if lum < _dark:
		_dark = lum
		_dark_p = p
	if count and DayCycle.is_day(now):
		_days += 1

## ④ 시계를 **놓아둔 채** 프레임만 돈다. `_ready` 에서 한 번 칠하고 마는 구현이
## ② 를 통과할 길은 없지만, 「`_process` 가 아니라 표본을 넣을 때만 도는」 배선이
## 있다면 여기서만 걸린다.
func _follow_clock() -> bool:
	_read(_follow == 0)          # 첫 프레임이 하루의 **마지막 표본**을 읽는다
	_follow += 1
	if _follow < FOLLOW:
		return false
	return _finish()

func _finish() -> bool:
	var ok := bad == 0
	if _worst > TOL:
		ok = false
		fail("하늘빛", "최대 어긋남 %.4f (%s)" % [_worst, _worst_at],
			"%.2f 이하 (main.gd 가 매 프레임 Sky 를 물들인다)" % TOL)
	if _bright < DAY_MIN:
		ok = false
		fail("한낮", "제일 밝은 표본 %.3f (위상 %.3f)" % [_bright, _bright_p],
			"%.2f 이상 (한낮은 곱이 1 이라 월드 색 그대로다)" % DAY_MIN)
	if _dark > NIGHT_MAX:
		ok = false
		fail("한밤", "제일 어두운 표본 %.3f (위상 %.3f)" % [_dark, _dark_p],
			"%.2f 이하 (밤이 낮과 구별돼야 한다)" % NIGHT_MAX)
	# 낮 10분 · 밤 10분 — 표본이 반반으로 갈린다 (GDD G-1b).
	if _days * 2 != SAMPLES:
		ok = false
		fail("낮의 몫", "표본 %d개 중 %d개가 낮" % [SAMPLES, _days],
			"%d개 (하루 20분 = 낮 10 + 밤 10)" % (SAMPLES / 2))
	if not ok:
		bad += 1
	print("DAY 한 바퀴  제일 밝음 %.3f (위상 %.3f) · 제일 어두움 %.3f (위상 %.3f) · 낮 %d/%d 표본" % [
		_bright, _bright_p, _dark, _dark_p, _days, SAMPLES])
	print("DAY %s (최대 어긋남 %.4f · 낮 %.0f 분 + 밤 %.0f 분 · 표본 %d + 따라가기 %d 프레임)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, _worst,
		WorldState.DAY_SEC * 0.5 / 60.0, WorldState.DAY_SEC * 0.5 / 60.0, SAMPLES, FOLLOW])
	_done = true
	return true

## 게이트가 죽을 때도 **제 요약 줄을 남긴다** — 침묵은 초록으로 읽히면 안 된다.
func _stop() -> bool:
	bad += 1
	print("DAY FAIL %d개 (하늘을 못 찾았다)" % bad)
	_done = true
	return true
