extends SceneTree

## **실측 게이트 — 창.** VIEW(화면)와 DRAW(그리기)를 **한 프로세스**에서 잰다.
##
## **왜 합쳤나** (바퀴 14): 둘 다 `--headless` 로는 못 돌고 둘 다 메인 씬을 세운다.
## 따로 돌리면 한 판에 창이 두 번 뜨고, **창을 띄우면 macOS 가 앱을 맨 앞으로
## 올린다 — 막는 길이 없다** (바퀴 13 · NUMBERS 11절). 못 막으니 **횟수를 줄인다.**
## 계약 한 판에 창 3번 → 2번, `redteam.sh` 한 판이면 93번 → 62번.
##
## **순서가 계약이다**: VIEW 를 먼저 잰다. DRAW 는 플레이어를 해안으로 순간이동시키고
## 걷게 하므로, 그 뒤에 화면을 재면 「처음 뜬 창」이 아니라 「걷다 만 화면」을 재게 된다.
##
## ── VIEW: 실제 창을 띄워 논리 화면·창 크기·배율·보이는 칸을 잰다 ──────────
## 왜 단위 검사로 부족한가: `test_project_settings.gd` 는 project.godot 의 **글자**를 읽는다.
## 값이 맞아도 실행 중에 카메라가 줌을 걸거나 코드가 content_scale_factor 를 만지면
## 눈에 보이는 칸 수는 달라진다 — 그런데 단위 검사는 전부 초록으로 남는다.
## (바퀴 3 에서 이동 속도로 똑같은 구멍을 확인했다. NUMBERS 5절)
## **헤드리스 드라이버는 창 크기가 (0,0) 이라 배율을 못 잰다** — 그래서 창이 필요하다.
##
## ── DRAW: 플레이어를 진짜 해안에 세우고 구운 픽셀을 그 자리의 월드 칸 색과 맞춘다 ──
## 왜 단위 검사로 부족한가: `WorldView` 가 아무리 맞아도 `main.gd` 가 안 그리거나,
## 다른 씨앗으로 그리거나, 카메라와 어긋난 자리에 그리면 **단위 검사는 전부 초록**이다.
## **픽셀만으로는 못 잡는 것이 하나 있다**: 월드를 65536칸 통째로 그려도 화면은 똑같다.
## 그래서 `main.gd` 가 세어 둔 `drawn_tiles` 를 같이 읽는다.
## **두 번 잰다 — 서고 나서, 그리고 걷고 나서.** main.gd 는 보이는 범위가 바뀔 때만
## 색을 다시 채우므로 캐시가 상하면 화면이 월드에서 미끄러진다.
## **걷는 구간에는 저만 잡는 대조군이 하나 있다** (redteam ⑤ · NUMBERS 9절):
## 캐시를 **두 칸 넘게 움직였을 때만** 다시 채우면 아래의 순간이동(101칸)은 멀쩡히
## 채우므로 `[서서]` 는 전부 맞고 **`[걷고]` 에서만** 어긋난다.
## **해안에 세우는 이유**: 스폰은 섬 한가운데라 화면이 전부 풀밭이다 — 「물을 파랗게
## 그리나」를 한 픽셀도 못 잰다. 스폰에서 +x 로 걸어 첫 바다를 찾아 그 경계에 세운다.
## **헤드리스는 렌더러가 더미라 뷰포트 텍스처가 빈다** (NUMBERS 3b절).
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

# ── VIEW 기대값 (NUMBERS 1절) ────────────────────────────────────────
const LOGICAL := Vector2(960.0, 540.0)
const WINDOW := Vector2(1920.0, 1080.0)
const SCALE := 2.0
const TILES := Vector2(30.0, 16.875)       # 960/32 · 540/32 (BACKLOG 고정값)

# 창 크기가 붙고 씬의 _ready(월드 배선)가 돌 때까지 기다리는 프레임.
# VIEW 는 5, DRAW 는 4가 필요했다 — 큰 쪽을 쓴다.
const WARMUP := 5

# ── DRAW 기대값 ──────────────────────────────────────────────────────
const LOGICAL_I := Vector2i(960, 540)
const SETTLE := 4                  # 순간이동·걷기 뒤 카메라가 따라붙을 시간
const STEP := 8                    # 표본 간격(px). 8 → 120 x 68 = 8160 점
# 화면 중심(= 플레이어 발밑)에서 이만큼은 건너뛴다. **원점이 발밑이라 위아래가 다르다**
# (바퀴 16): 몸통이 위로 40 · 아래로 8 이고, 위를 볼 때 코 끝이 48 까지 간다. 옆은 24 다.
# 큰 쪽(48)에 여유를 얹은 값이라 네모가 표본에 안 섞인다.
const SKIP_BOX := 56.0
const TOL := 2.0 / 255.0           # 8비트로 두 칸. 렌더러가 반올림할 자리를 남긴다
const MIN_SHARE := 0.15            # 물·땅이 각각 이만큼은 화면에 있어야 판정이 공허하지 않다
const MAX_TILES := 700             # 31 x 18 = 558. 통째로 그리면 65536 이다
const WALK := 3.0 * PlayerMotion.TILE   # 걷는 거리(px). 3칸이면 캐시가 반드시 한 번은 다시 찬다
const WALK_FRAMES := 300           # 안전벨트. 막혀서 못 걸으면 여기서 끊는다

var _view_bad := 0
var _draw_bad := 0
var _frames := 0
var _main: Node2D
var _player: Node2D
var _seed := 0

func _initialize() -> void:
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	root.add_child(_main)
	for i in WARMUP:
		await process_frame
		_frames += 1

	_measure_view()
	await _measure_draw()
	_finish()

# ── VIEW ─────────────────────────────────────────────────────────────
func _measure_view() -> void:
	var driver := DisplayServer.get_name()
	if driver == "headless":
		_view_fail("드라이버", "headless 로는 창을 못 잰다 — --headless 없이 불러라", "macOS/X11")
		_view_report(driver)
		return

	var vis := root.get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	_v2("논리 화면", vis, LOGICAL)
	_v2("창", win, WINDOW)

	# 배율은 나눗셈이 아니라 **엔진이 실제로 거는 변환**에서 잰다.
	# content_scale_factor 를 만지면 여기서 잡힌다.
	var fs := root.get_final_transform().get_scale()
	_v2("최종 변환 배율", fs, Vector2(SCALE, SCALE))
	_num("정수 배율", fs.x, roundf(fs.x))       # 소수 배율이면 도트가 뭉갠다

	# 보이는 칸은 **월드 좌표**로 잰다 — 카메라 줌이 걸리면 여기서만 달라진다.
	var cz := root.get_canvas_transform().get_scale()
	var world := Vector2(vis.x / cz.x, vis.y / cz.y)
	var tiles := world / PlayerMotion.TILE
	_v2("보이는 칸", tiles, TILES)

	print("VIEW 논리 %.0fx%.0f · 창 %.0fx%.0f · 배율 %.2fx · 카메라 %.2fx · 타일 %dpx · 보이는 칸 %.2f x %.2f" % [
		vis.x, vis.y, win.x, win.y, fs.x, cz.x, int(PlayerMotion.TILE), tiles.x, tiles.y])
	_view_report(driver)

func _view_report(driver: String) -> void:
	print("VIEW %s (드라이버 %s · 프레임 %d)" % [
		"ok" if _view_bad == 0 else "FAIL %d개" % _view_bad, driver, _frames])

func _view_fail(what: String, actual: String, expected: String) -> void:
	_view_bad += 1
	print("VIEW FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])

func _num(what: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		_view_fail(what, "%.4f" % actual, "%.4f" % expected)

func _v2(what: String, actual: Vector2, expected: Vector2) -> void:
	if not (is_equal_approx(actual.x, expected.x) and is_equal_approx(actual.y, expected.y)):
		_view_fail(what, "%.2f x %.2f" % [actual.x, actual.y], "%.2f x %.2f" % [expected.x, expected.y])

# ── DRAW ─────────────────────────────────────────────────────────────
func _measure_draw() -> void:
	_player = _main.get_node_or_null("Player") as Node2D
	if _player == null:
		_draw_fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		return
	_seed = _main.WORLD_SEED

	# ── 1. 서서 ───────────────────────────────────────────────────
	var coast := _coast_tile()
	_player.global_position = _center_of(coast)
	print("DRAW 해안 칸 %s · 플레이어 %s" % [coast, _player.global_position])
	await _settle()
	_draw_measure("서서")

	# ── 2. 걷고 나서 ──────────────────────────────────────────────
	# 왼쪽(섬 안쪽)으로 간다. 오른쪽은 바다라 막혀서 안 움직인다.
	var walked := await _walk("move_left")
	await _settle()
	_draw_measure("걷고 %.0f px" % walked)
	if walked < WALK:
		_draw_fail("걸은 거리", "%.2f px" % walked,
			"%.0f px 이상 (안 걸으면 캐시가 상했는지 못 잰다)" % WALK)

## 스폰에서 +x 로 걸어 처음 만나는 바다. 그 **앞 칸(마지막 땅)**이 해안이다.
func _coast_tile() -> Vector2i:
	var t := WorldGen.spawn_tile()
	while t.x < WorldGen.SIZE and WorldGen.tile_at(_seed, t.x, t.y) == WorldGen.LAND:
		t.x += 1
	return Vector2i(t.x - 1, t.y)

func _center_of(tile: Vector2i) -> Vector2:
	return Vector2(tile) * PlayerMotion.TILE + Vector2.ONE * (PlayerMotion.TILE * 0.5)

func _settle() -> void:
	for i in SETTLE:
		await process_frame
	await RenderingServer.frame_post_draw

func _walk(action: String) -> float:
	var from := _player.global_position
	Input.action_press(action)
	for i in WALK_FRAMES:
		await process_frame
		if from.distance_to(_player.global_position) >= WALK:
			break
	Input.action_release(action)
	return from.distance_to(_player.global_position)

## 지금 화면을 구워서 월드와 맞춘다.
func _draw_measure(phase: String) -> void:
	var tex: ViewportTexture = root.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.get_width() == 0:
		_draw_fail("화면 [%s]" % phase, "텍스처가 비었다", "%s (--headless 로 띄웠나?)" % LOGICAL_I)
		return
	if img.get_width() != LOGICAL_I.x or img.get_height() != LOGICAL_I.y:
		_draw_fail("화면 크기 [%s]" % phase, "%dx%d" % [img.get_width(), img.get_height()],
			"%dx%d" % [LOGICAL_I.x, LOGICAL_I.y])
		return
	_compare(img, phase)

## 화면의 점 하나하나를 월드 좌표로 되돌려 **그 칸의 색**과 맞춘다.
## 되돌리는 데 쓰는 것이 캔버스 변환이므로, 카메라가 어긋나 있으면 여기서 통째로 빨개진다.
func _compare(img: Image, phase: String) -> void:
	var inv := root.get_canvas_transform().affine_inverse()
	var center := Vector2(LOGICAL_I) * 0.5
	var n := 0
	var miss := 0
	var water := 0
	var worst := 0.0
	var first := ""
	for sy in range(STEP / 2, LOGICAL_I.y, STEP):
		for sx in range(STEP / 2, LOGICAL_I.x, STEP):
			var screen := Vector2(sx, sy)
			if absf(screen.x - center.x) < SKIP_BOX and absf(screen.y - center.y) < SKIP_BOX:
				continue                      # 플레이어 네모가 덮은 자리
			var w: Vector2 = inv * (screen + Vector2(0.5, 0.5))
			var tx := WorldCollide.tile_of(w.x)
			var ty := WorldCollide.tile_of(w.y)
			n += 1
			if WorldGen.tile_at(_seed, tx, ty) == WorldGen.WATER:
				water += 1
			var want := WorldView.color_at(_seed, tx, ty)
			var got := img.get_pixel(sx, sy)
			var d := maxf(maxf(absf(want.r - got.r), absf(want.g - got.g)), absf(want.b - got.b))
			if d > worst:
				worst = d
			if d > TOL:
				miss += 1
				if first == "":
					first = "화면 (%d,%d) → 칸 (%d,%d) · 잰 값 %s · 기대 %s" % [
						sx, sy, tx, ty, got.to_html(false), want.to_html(false)]

	var wet := 100.0 * water / n
	var drawn: int = _main.drawn_tiles
	print("DRAW [%s] 표본 %d · 불일치 %d · 최대 색차 %.1f/255 · 물 %.1f%% · 땅 %.1f%% · 그린 칸 %d · 채운 횟수 %d" % [
		phase, n, miss, worst * 255.0, wet, 100.0 - wet, drawn, _main.cache_fills])

	if miss > 0:
		_draw_fail("화면이 월드와 다르다 [%s]" % phase, "%d / %d 점 (첫 어긋남: %s)" % [miss, n, first],
			"전부 일치 (허용 색차 %.1f/255)" % (TOL * 255.0))
	if wet < MIN_SHARE * 100.0 or wet > (1.0 - MIN_SHARE) * 100.0:
		_draw_fail("해안이 화면에 없다 [%s]" % phase, "물 %.1f%% · 땅 %.1f%%" % [wet, 100.0 - wet],
			"각각 %.0f%% 이상 (한 지형만이면 색 판정이 공허하다)" % (MIN_SHARE * 100.0))
	if drawn <= 0 or drawn > MAX_TILES:
		_draw_fail("그린 칸 수 [%s]" % phase, "%d 칸" % drawn,
			"1 .. %d 칸 (보이는 칸만 — 월드는 %d 칸이다)" % [MAX_TILES, WorldGen.SIZE * WorldGen.SIZE])

func _draw_fail(what: String, actual: String, expected: String) -> void:
	_draw_bad += 1
	print("DRAW FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])

# ── 끝 ───────────────────────────────────────────────────────────────
## **둘 중 하나만 빨개도 이 프로세스는 빨갛다.** 합치기 전에도 계약은 둘 다 봤다.
func _finish() -> void:
	print("DRAW %s (표본 간격 %d px · 중심 %.0f px 제외 · 서서 + 걷고 두 번)" % [
		"ok" if _draw_bad == 0 else "FAIL %d개" % _draw_bad, STEP, SKIP_BOX])
	# 이름이 `WINGATE` 인 이유: `main.gd` 가 시작할 때 `WINDOW   1920 x 1080` 을 찍는다 —
	# `WINDOW` 로 시작하면 check.sh 의 grep 이 게이트가 죽어도 그 줄을 잡아 초록으로 본다.
	print("WINGATE %s (VIEW %d · DRAW %d · 창 한 번)" % [
		"ok" if _view_bad + _draw_bad == 0 else "FAIL %d개" % (_view_bad + _draw_bad),
		_view_bad, _draw_bad])
	if _main != null:
		_main.queue_free()
	quit(1 if _view_bad + _draw_bad > 0 else 0)
