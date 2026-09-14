extends SceneTree

## **실측 게이트 — 창.** VIEW(화면)와 DRAW(그리기)를 **한 프로세스**에서 잰다.
##
## **왜 합쳤나** (회차 14): 둘 다 `--headless` 로는 못 돌고 둘 다 메인 씬을 세운다.
## 따로 돌리면 한 판에 창이 두 번 뜨고, **창을 띄우면 macOS 가 앱을 맨 앞으로
## 올린다 — 막는 길이 없다** (회차 13 · NUMBERS 11절). 못 막으니 **횟수를 줄인다.**
## 상태 검사 한 판에 창 3번 → 2번, `redteam.sh` 한 판이면 93번 → 62번.
##
## **순서가 상태 검사가다**: VIEW 를 먼저 잰다. DRAW 는 플레이어를 해안으로 순간이동시키고
## 걷게 하므로, 그 뒤에 화면을 재면 「처음 뜬 창」이 아니라 「걷다 만 화면」을 재게 된다.
##
## ── VIEW: 실제 창을 띄워 논리 화면·창 크기·배율·보이는 칸을 잰다 ──────────
## 왜 단위 검사로 부족한가: `test_project_settings.gd` 는 project.godot 의 **글자**를 읽는다.
## 값이 맞아도 실행 중에 카메라가 줌을 걸거나 코드가 content_scale_factor 를 만지면
## 눈에 보이는 칸 수는 달라진다 — 그런데 단위 검사는 전부 초록으로 남는다.
## (회차 3 에서 이동 속도로 똑같은 구멍을 확인했다. NUMBERS 5절)
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
## ── HOTBAR: 화면 아래 9칸이 **정말 거기 그려졌나** · 숫자키가 손을 옮기나 ──────
## 왜 단위 검사로 부족한가: `test_hotbar.gd` 는 「9칸 자리의 기하」를 재고
## `test_player_scene.gd` 는 「씬에 달렸나 · 키가 묶였나」를 잰다. 셋 다 초록인 채로
## **핫바를 숨기거나**(`visible = false`) **숫자키를 안 읽거나**(`_poll_hotbar` 를 안 부른다)
## **손에 든 칸을 똑같이 그려도** 한 줄이 안 빨개진다 — 전부 실행 중의 픽셀이기 때문이다.
## 그래서 여기서 **칸마다 두 점**(테두리 · 바탕)을 구운 픽셀에서 읽고,
## **숫자키를 눌러 강조가 옮겨 가는지**까지 다시 굽는다.
##
## ── USE: 좌클릭이 **대상 없이도** 모션을 내나 · 그 모션이 움직이나 ───────────
## 왜 단위 검사로 부족한가: `test_hand_swing.gd` 는 부채꼴의 기하를, `test_player_scene.gd`
## 는 「씬에 네모가 있나 · 버튼이 묶였나」를 잰다. 둘 다 초록인 채로 **main 이 클릭을
## 안 읽거나**(`_poll_use` 를 안 부른다) **네모를 안 보이게 두거나**(`visible`)
## **손에 든 것과 무관한 색으로 그려도** 한 줄이 안 빨개진다.
## 그래서 여기서 **모션이 도는 동안 프레임마다** 네모의 자리를 모으고 그 자리의 픽셀을
## 읽는다: 자리가 안 변하면 그건 모션이 아니라 켜진 네모다.
## **맞힐 것이 하나도 없는 곳에서 잰다** — 월드에는 아직 오브젝트가 없다.
## 맨손으로 한 번 · 손에 든 것으로 한 번, 두 모션을 본다.
##
## **DRAW 는 핫바가 덮은 자리를 건너뛴다.** 안 그러면 「월드를 그렸나」가 핫바 때문에
## 통째로 빨개진다 — 건너뛴 만큼은 HOTBAR 가 대신 판정한다. 그래서 둘은 짝이다.
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

# ── VIEW 기대값 (NUMBERS 1절) ────────────────────────────────────────
const LOGICAL := Vector2(960.0, 540.0)
const WINDOW := Vector2(1920.0, 1080.0)
const SCALE := 2.0
const TILES := Vector2(60.0, 33.75)        # 960/16 · 540/16 (BACKLOG 고정값 · 회차 17)

# 창 크기가 붙고 씬의 _ready(월드 배선)가 돌 때까지 기다리는 프레임.
# VIEW 는 5, DRAW 는 4가 필요했다 — 큰 쪽을 쓴다.
const WARMUP := 5

# ── DRAW 기대값 ──────────────────────────────────────────────────────
const LOGICAL_I := Vector2i(960, 540)
const SETTLE := 4                  # 순간이동·걷기 뒤 카메라가 따라붙을 시간
const STEP := 8                    # 표본 간격(px). 8 → 120 x 68 = 8160 점
# 화면 중심(= 플레이어 발밑)에서 이만큼은 건너뛴다. **원점이 발밑이라 위아래가 다르다**
# (회차 16): 몸통이 위로 28 · 아래로 4 이고, 위를 볼 때 코 끝이 32 까지 간다. 옆은 12 다.
# 큰 쪽(32)에 여유를 얹은 값이라 네모가 표본에 안 섞인다 (회차 17: 56 → 40).
const SKIP_BOX := 40.0
const TOL := 2.0 / 255.0           # 8비트로 두 칸. 렌더러가 반올림할 자리를 남긴다
const MIN_SHARE := 0.15            # 물·땅이 각각 이만큼은 화면에 있어야 판정이 공허하지 않다
const MAX_TILES := 2400            # 61 x 35 = 2135. 통째로 그리면 65536 이다
const WALK := 3.0 * PlayerMotion.TILE   # 걷는 거리(px). 3칸이면 캐시가 반드시 한 번은 다시 찬다
const WALK_FRAMES := 300           # 안전벨트. 막혀서 못 걸으면 여기서 끊는다

# ── HOTBAR 기대값 ────────────────────────────────────────────────────
# 칸 안에서 읽는 두 점(칸의 왼쪽 위 모서리로부터). **자리가 겹치면 안 된다**:
#   테두리 — 칸 위쪽 변 한가운데. 두께 2px 안이다
#   바탕   — 테두리 밖 · 아이템 네모(안쪽 6px) 밖. 칸이 비든 차든 늘 바탕색이다
const HB_EDGE_PROBE := Vector2(HotbarView.SLOT * 0.5, 1.0)
const HB_BG_PROBE := Vector2(4.0, 4.0)
const HB_KEY := 3                  # 눌러 볼 숫자키. 처음 든 1번 칸과 달라야 옮겨간 것이 보인다
const HB_BOTTOM_GAP := 16.0        # 화면 아래 끝에서 이보다 멀면 「상시 핫바」가 아니다

# ── USE 기대값 ───────────────────────────────────────────────────────
# **대상이 없어도 모션이 나온다** (BACKLOG P2). 이 게이트가 서는 자리가 그 문장이다:
# 월드에는 아직 오브젝트가 하나도 없고 플레이어는 맨땅(또는 바다)을 겨눈다.
const USE_ITEM := &"wood"          # 손에 들려 볼 것. 맨손과 색이 달라야 「든 것」이 보인다
const USE_EMPTY_SLOT := 8          # 맨손을 만들 빈 칸
const USE_MAX_FRAMES := 40         # 한 모션에서 따라가는 프레임 상한 (화면이 빠른 기계 대비)
const USE_UNTIL := 0.6             # 진행도가 여기까지 오면 그만 본다
const USE_MIN_FRAMES := 3          # 그 전에 최소 이만큼은 본다
const USE_MIN_SPOTS := 3           # 서로 다른 자리가 이만큼은 나와야 「모션」이다
const USE_MIN_SPAN := 4.0          # 처음과 끝이 이만큼은 벌어져야 한다 (px)
const USE_SAME := 0.5              # 이보다 가까우면 같은 자리로 센다 (px)
const USE_END_FRAMES := 120        # 버튼을 놓고 모션이 끝나기를 기다리는 상한

var _view_bad := 0
var _draw_bad := 0
var _hb_bad := 0
var _use_bad := 0
var _use_swings := 0
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
	await _measure_hotbar()
	await _measure_use()
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
	# **핫바가 덮은 자리는 월드가 아니다.** 건너뛴 만큼은 아래 HOTBAR 가 판정한다.
	var bar := HotbarView.bar_rect(Vector2(LOGICAL_I)).grow(1.0)
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
			if bar.has_point(screen):
				continue                      # 핫바가 덮은 자리 (HOTBAR 가 본다)
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
	# **채우는 데 걸린 시간을 같이 찍는다** (회차 17): 칸이 3.8배로 늘어 한 판이 프레임
	# 예산(16667 µs)에 얼마나 가까운지가 눈이 아니라 숫자로만 보인다.
	print("DRAW [%s] 표본 %d · 불일치 %d · 최대 색차 %.1f/255 · 물 %.1f%% · 땅 %.1f%% · 그린 칸 %d · 채운 횟수 %d · 마지막 채우기 %d µs" % [
		phase, n, miss, worst * 255.0, wet, 100.0 - wet, drawn, _main.cache_fills, _main.fill_usec])

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

# ── HOTBAR ───────────────────────────────────────────────────────────
## 화면 아래 9칸을 **구운 픽셀에서** 읽고, 숫자키를 눌러 손이 옮겨 가는지 다시 굽는다.
##
## DRAW 가 이 자리를 건너뛰므로 **여기가 그 자리의 유일한 판정**이다.
## 「핫바가 있다」로는 부족하다 — 숨겨도 · 안 그려도 · 다 같은 색으로 그려도
## 씬과 단위 검사는 전부 초록이다.
func _measure_hotbar() -> void:
	var view: Control = _main.get_node_or_null("UI/Hotbar") as Control
	if view == null:
		_hb_fail("핫바", "Main/UI/Hotbar 가 없다", "메인 씬에 HotbarView")
		_hb_report()
		return
	var hotbar = _main.hotbar
	var screen := Vector2(LOGICAL_I)
	var bar := HotbarView.bar_rect(screen)

	# ① **화면에 못 박혀 있다.** 걷고 난 뒤인데도 자리가 그대로여야 한다 —
	#    CanvasLayer 를 벗기면 카메라를 타고 흘러가서 여기서 잡힌다.
	var got := Rect2(view.global_position, view.size)
	if not (got.position.is_equal_approx(bar.position) and got.size.is_equal_approx(bar.size)):
		_hb_fail("핫바 자리 (걷고 난 뒤)", str(got), str(bar))
	if not view.visible:
		_hb_fail("핫바", "안 보인다 (visible = false)", "상시 표시")
	if screen.y - bar.end.y > HB_BOTTOM_GAP or bar.end.y > screen.y:
		_hb_fail("핫바가 화면 아래에 안 붙었다", "아래 여백 %.1f px" % (screen.y - bar.end.y),
			"0 .. %.0f px" % HB_BOTTOM_GAP)

	# ② **9칸이 정말 그려져 있다.** 칸마다 두 점을 읽는다.
	await _settle()
	var img := _bake()
	if img == null:
		_hb_fail("화면", "텍스처가 비었거나 크기가 다르다", "%s" % LOGICAL_I)
		_hb_report()
		return
	_hb_pixels(img, "처음", hotbar.selected)

	# ③ **숫자키가 손을 옮긴다.** 상태(`selected`)와 픽셀(강조 테두리)을 둘 다 본다 —
	#    상태만 보면 「손은 옮겼는데 화면이 그대로」를, 픽셀만 보면 계산을 못 잡는다.
	var before: int = hotbar.selected
	await _press(Hotbar.action_for(HB_KEY - 1))
	if hotbar.selected != HB_KEY - 1:
		_hb_fail("숫자키 %d 를 눌렀는데 손이 안 옮겨갔다" % HB_KEY,
			"%d번 칸" % (hotbar.selected + 1), "%d번 칸 (누르기 전 %d번)" % [HB_KEY, before + 1])
	await _settle()
	var img2 := _bake()
	if img2 == null:
		_hb_fail("화면 (숫자키 뒤)", "텍스처가 비었거나 크기가 다르다", "%s" % LOGICAL_I)
	else:
		_hb_pixels(img2, "숫자키 %d" % HB_KEY, HB_KEY - 1)
	_hb_report()

## 지금 화면을 굽는다. 비었거나 크기가 다르면 null 이다 — **보고는 부르는 쪽이 한다**
## (HOTBAR 와 USE 가 같이 쓴다).
func _bake() -> Image:
	var tex: ViewportTexture = root.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.get_width() != LOGICAL_I.x or img.get_height() != LOGICAL_I.y:
		return null
	return img

## 9칸의 테두리·바탕 픽셀을 전부 읽는다. **든 칸 하나만 테두리 색이 달라야 한다.**
func _hb_pixels(img: Image, phase: String, held: int) -> void:
	var screen := Vector2(LOGICAL_I)
	var bad := 0
	var lit := 0
	var first := ""
	for i in Hotbar.SLOTS:
		var r := HotbarView.slot_rect(i, screen)
		var edge := img.get_pixel(int(r.position.x + HB_EDGE_PROBE.x), int(r.position.y + HB_EDGE_PROBE.y))
		var bg := img.get_pixel(int(r.position.x + HB_BG_PROBE.x), int(r.position.y + HB_BG_PROBE.y))
		var want: Color = HotbarView.EDGE_HELD if i == held else HotbarView.EDGE
		if _near(edge, HotbarView.EDGE_HELD):
			lit += 1
		if not _near(edge, want):
			bad += 1
			if first == "":
				first = "%d번 칸 테두리 · 잰 값 %s · 기대 %s" % [i + 1, edge.to_html(false), want.to_html(false)]
		if not _near(bg, HotbarView.BG):
			bad += 1
			if first == "":
				first = "%d번 칸 바탕 · 잰 값 %s · 기대 %s" % [i + 1, bg.to_html(false), HotbarView.BG.to_html(false)]
	print("HOTBAR [%s] 칸 %d · 어긋남 %d · 강조된 칸 %d · 손 %d번 · 줄 %s" % [
		phase, Hotbar.SLOTS, bad, lit, held + 1, HotbarView.bar_rect(screen)])
	if bad > 0:
		_hb_fail("핫바가 화면에 없거나 다르게 그려졌다 [%s]" % phase,
			"%d / %d 점 (첫 어긋남: %s)" % [bad, Hotbar.SLOTS * 2, first],
			"9칸 전부 일치 (허용 색차 %.1f/255)" % (TOL * 255.0))
	# **강조는 정확히 하나다.** 전부 켜지거나 전부 꺼지면 숫자키가 화면에 안 보인다.
	if lit != 1:
		_hb_fail("손에 든 칸 표시 [%s]" % phase, "%d칸이 강조됐다" % lit, "정확히 1칸")

## 숫자키를 **몇 프레임 눌러 둔다.** `Input.action_press` 는 이벤트를 안 흘려보내고
## 상태만 바꾸므로, 받는 쪽이 `_process` 에서 폴링해야 한다 (main.gd `_poll_hotbar`).
func _press(action: StringName) -> void:
	Input.action_press(action)
	for i in SETTLE:
		await process_frame
	Input.action_release(action)
	await process_frame

func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) <= TOL and absf(a.g - b.g) <= TOL and absf(a.b - b.b) <= TOL

func _hb_fail(what: String, actual: String, expected: String) -> void:
	_hb_bad += 1
	print("HOTBAR FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])

func _hb_report() -> void:
	print("HOTBAR %s (9칸 × 두 점 · 숫자키 %d 를 눌러 다시 굽는다)" % [
		"ok" if _hb_bad == 0 else "FAIL %d개" % _hb_bad, HB_KEY])

# ── USE ──────────────────────────────────────────────────────────────
## 좌클릭 → **손에 든 것의 동작.** 맞힐 것이 없어도 모션이 나오고, 그 모션이 움직인다.
##
## **DRAW 보다 뒤에 있어야 한다**: 휘두르는 네모는 플레이어 둘레에 뜨는데 DRAW 는
## 그 자리를 「월드와 같은 색이어야 한다」로 본다. 안 휘두르는 동안에는 네모가 아예
## 없으므로 앞의 두 게이트는 이 항목이 생겨도 표본 한 점을 안 잃는다.
func _measure_use() -> void:
	var tool_rect := _player.get_node_or_null("Tool") as ColorRect
	var body := _player.get_node_or_null("Body") as ColorRect
	if tool_rect == null or body == null:
		_use_fail("휘두르는 네모", "Player/Tool 이나 Player/Body 가 없다", "플레이어 씬에 둘 다")
		_use_report()
		return

	# ① **안 휘두를 때는 화면에 없다.** 늘 떠 있으면 모션이 아니라 장식이다.
	if tool_rect.visible:
		_use_fail("좌클릭 전", "휘두르는 네모가 이미 보인다", "안 보인다")

	# ② **맨손도 휘두른다** (GDD D-2c 맨손 채집). 빈 칸을 든다.
	_main.hotbar.select(USE_EMPTY_SLOT)
	await _swing_once("맨손", HandSwing.BARE, tool_rect, body)

	# ③ **손에 든 것의 색으로 휘두른다.** 목재를 넣고 그 칸을 든다 —
	#    색이 늘 같으면 무엇을 휘두르는지 화면에서 못 읽는다.
	_main.hotbar.items.add(USE_ITEM, 3)
	_main.hotbar.select(0)
	await _swing_once("목재", HotbarView.item_color(USE_ITEM), tool_rect, body)
	_use_report()

## 한 모션을 **프레임마다 따라간다.** 버튼을 쥐고 있다가, 진행도가 USE_UNTIL 을 넘으면 놓는다.
func _swing_once(phase: String, want: Color, tool_rect: ColorRect, body: ColorRect) -> void:
	var action: StringName = _main.USE_ACTION
	Input.action_press(action)
	var spots: Array[Vector2] = []
	var px_bad := 0
	var geo_bad := 0
	var first := ""
	var frames := 0
	for i in USE_MAX_FRAMES:
		await process_frame
		await RenderingServer.frame_post_draw
		frames += 1
		if not tool_rect.visible:
			_use_fail("모션 [%s]" % phase, "%d 프레임째에 네모가 사라졌다 (진행도 %.2f)" % [
				frames, _player.swing.progress()], "버튼을 쥐고 있는 동안 계속 보인다")
			break
		var center: Vector2 = tool_rect.global_position + tool_rect.size * 0.5
		spots.append(center)

		# 기하 — **몸통 한가운데에서 사거리만큼 · 겨눈 부채꼴 안.**
		var hub: Vector2 = _player.global_position + body.position + body.size * 0.5
		var d := hub.distance_to(center)
		var deg := rad_to_deg(absf((center - hub).angle_to(_player.facing)))
		if absf(d - HandSwing.REACH) > 0.01 or deg > HandSwing.ARC_DEG * 0.5 + 0.01:
			geo_bad += 1
			if first == "":
				first = "자리 · 사거리 %.2f px (기대 %.1f) · 벌어진 각 %.2f도 (기대 %.1f 이하)" % [
					d, HandSwing.REACH, deg, HandSwing.ARC_DEG * 0.5]

		# 픽셀 — **그 자리에 정말 그 색이 그려졌나.**
		var img := _bake()
		if img == null:
			_use_fail("화면 [%s]" % phase, "텍스처가 비었거나 크기가 다르다", "%s" % LOGICAL_I)
			break
		var sp := root.get_canvas_transform() * center
		var got := img.get_pixel(clampi(int(sp.x), 0, LOGICAL_I.x - 1), clampi(int(sp.y), 0, LOGICAL_I.y - 1))
		if not _near(got, want):
			px_bad += 1
			if first == "":
				first = "화면 (%d,%d) · 잰 값 %s · 기대 %s" % [
					int(sp.x), int(sp.y), got.to_html(false), want.to_html(false)]
		if frames >= USE_MIN_FRAMES and _player.swing.progress() >= USE_UNTIL:
			break
	Input.action_release(action)

	# **모션은 「네모가 뜬다」가 아니라 「네모가 움직인다」다.**
	var distinct := 0
	var span := 0.0
	for a in spots.size():
		var same := false
		for b in a:
			if spots[a].distance_to(spots[b]) <= USE_SAME:
				same = true
			span = maxf(span, spots[a].distance_to(spots[b]))
		if not same:
			distinct += 1
	_use_swings += 1
	print("USE [%s] 프레임 %d · 자리 %d · 벌어짐 %.2f px · 픽셀 어긋남 %d · 기하 어긋남 %d · 색 %s · 진행도 %.2f" % [
		phase, frames, distinct, span, px_bad, geo_bad, want.to_html(false), _player.swing.progress()])
	if px_bad > 0:
		_use_fail("휘두르는 네모가 화면에 없거나 다른 색이다 [%s]" % phase,
			"%d / %d 프레임 (첫 어긋남: %s)" % [px_bad, frames, first],
			"매 프레임 손에 든 것의 색 (허용 색차 %.1f/255)" % (TOL * 255.0))
	if geo_bad > 0:
		_use_fail("휘두르는 네모가 엉뚱한 자리다 [%s]" % phase,
			"%d / %d 프레임 (첫 어긋남: %s)" % [geo_bad, frames, first], "사거리 위 · 부채꼴 안")
	if distinct < USE_MIN_SPOTS or span < USE_MIN_SPAN:
		_use_fail("모션이 안 움직인다 [%s]" % phase,
			"서로 다른 자리 %d개 · 벌어짐 %.2f px" % [distinct, span],
			"%d개 이상 · %.1f px 이상 (한 자리에 붙박이면 모션이 아니다)" % [USE_MIN_SPOTS, USE_MIN_SPAN])

	# ④ **놓으면 끝난다.** 안 끝나면 네모가 화면에 영영 남는다.
	var waited := 0
	for i in USE_END_FRAMES:
		await process_frame
		waited += 1
		if not tool_rect.visible:
			break
	if tool_rect.visible:
		_use_fail("버튼을 놓은 뒤 [%s]" % phase, "%d 프레임을 기다려도 네모가 남아 있다" % waited,
			"%.2f초 안에 사라진다" % HandSwing.SWING_SEC)

func _use_fail(what: String, actual: String, expected: String) -> void:
	_use_bad += 1
	print("USE FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])

func _use_report() -> void:
	print("USE %s (모션 %d번 · **대상 0개** · 사거리 %.0f px · 부채꼴 %.0f도 · %.2f초)" % [
		"ok" if _use_bad == 0 else "FAIL %d개" % _use_bad, _use_swings,
		HandSwing.REACH, HandSwing.ARC_DEG, HandSwing.SWING_SEC])

# ── 끝 ───────────────────────────────────────────────────────────────
## **넷 중 하나만 빨개도 이 프로세스는 빨갛다.** 합치기 전에도 상태 검사는 전부 봤다.
func _finish() -> void:
	print("DRAW %s (표본 간격 %d px · 중심 %.0f px 제외 · 서서 + 걷고 두 번)" % [
		"ok" if _draw_bad == 0 else "FAIL %d개" % _draw_bad, STEP, SKIP_BOX])
	# 이름이 `WINGATE` 인 이유: `main.gd` 가 시작할 때 `WINDOW   1920 x 1080` 을 찍는다 —
	# `WINDOW` 로 시작하면 check.sh 의 grep 이 게이트가 죽어도 그 줄을 잡아 초록으로 본다.
	var bad := _view_bad + _draw_bad + _hb_bad + _use_bad
	print("WINGATE %s (VIEW %d · DRAW %d · HOTBAR %d · USE %d · 창 한 번)" % [
		"ok" if bad == 0 else "FAIL %d개" % bad, _view_bad, _draw_bad, _hb_bad, _use_bad])
	if _main != null:
		_main.queue_free()
	quit(1 if bad > 0 else 0)
