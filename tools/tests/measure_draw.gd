extends SceneTree

## **실측 게이트 — 그리기.** 메인 씬을 통째로 띄워 **플레이어를 진짜 해안에 세우고**,
## 구운 화면의 픽셀 하나하나를 **그 자리의 월드 칸 색과 맞춰 본다.**
##
## 왜 단위 검사로 부족한가: `WorldView` 가 아무리 맞아도 `main.gd` 가 안 그리거나,
## 다른 씨앗으로 그리거나, 카메라와 어긋난 자리에 그리면 **단위 검사는 전부 초록**이다.
## (바퀴 3 속도 · 4 화면 · 5 방향 · 6 월드 · 7 충돌 · 8 카메라와 **같은 모양의 구멍**이다)
##
## **픽셀만으로는 못 잡는 것이 하나 있다**: 월드를 65536칸 통째로 그려도 화면은 똑같다.
## 그래서 `main.gd` 가 세어 둔 `drawn_tiles` 를 같이 읽는다.
##
## **두 번 잰다 — 서고 나서, 그리고 걷고 나서.** main.gd 는 보이는 범위가 바뀔 때만
## 색을 다시 채우므로, 캐시가 상하면 **화면이 월드에서 미끄러진다.** 사람 눈에는
## 「걸으면 땅이 어긋난다」로만 보이고 서 있을 때는 멀쩡하다 — 한 번만 재면 못 잡는다.
##
## **해안에 세우는 이유**: 스폰은 섬 한가운데라 화면이 전부 풀밭이다. 그러면
## 「물을 파랗게 그리나」를 한 픽셀도 못 잰다. 스폰에서 +x 로 걸어 첫 바다를 찾아
## 그 경계에 세운다 — 화면에 물과 땅이 같이 들어온다.
##
## **`--headless` 로는 못 쓴다** — 렌더러가 더미라 뷰포트 텍스처가 빈다 (NUMBERS 3b절).
##
## 이름이 test_ 로 시작하지 않는다 — run_tests.gd 는 이 파일을 안 집는다.

const LOGICAL := Vector2i(960, 540)
const WARMUP := 4                  # 씬의 _ready(월드 배선)는 첫 프레임 뒤에 돈다
const SETTLE := 4                  # 순간이동·걷기 뒤 카메라가 따라붙을 시간
const STEP := 8                    # 표본 간격(px). 8 → 120 x 68 = 8160 점
const SKIP_BOX := 56.0             # 화면 중심에서 이만큼은 건너뛴다 (몸 24 · 코 36)
const TOL := 2.0 / 255.0           # 8비트로 두 칸. 렌더러가 반올림할 자리를 남긴다
const MIN_SHARE := 0.15            # 물·땅이 각각 이만큼은 화면에 있어야 판정이 공허하지 않다
const MAX_TILES := 400             # 21 x 13 = 273. 통째로 그리면 65536 이다
const WALK := 3.0 * 48.0           # 걷는 거리(px). 3칸이면 캐시가 반드시 한 번은 다시 찬다
const WALK_FRAMES := 300           # 안전벨트. 막혀서 못 걸으면 여기서 끊는다

var _bad := 0
var _main: Node2D
var _player: Node2D
var _seed := 0

func _initialize() -> void:
	var scene: String = ProjectSettings.get_setting("application/run/main_scene")
	_main = load(scene).instantiate()
	root.add_child(_main)
	for i in WARMUP:
		await process_frame

	_player = _main.get_node_or_null("Player") as Node2D
	if _player == null:
		_fail("플레이어", "Main/Player 가 없다", "메인 씬에 플레이어")
		_finish()
		return
	_seed = _main.WORLD_SEED

	# ── 1. 서서 ───────────────────────────────────────────────────
	var coast := _coast_tile()
	_player.global_position = _center_of(coast)
	print("DRAW 해안 칸 %s · 플레이어 %s" % [coast, _player.global_position])
	await _settle()
	_measure("서서")

	# ── 2. 걷고 나서 ──────────────────────────────────────────────
	# 왼쪽(섬 안쪽)으로 간다. 오른쪽은 바다라 막혀서 안 움직인다.
	var walked := await _walk("move_left")
	await _settle()
	_measure("걷고 %.0f px" % walked)
	if walked < WALK:
		_fail("걸은 거리", "%.2f px" % walked,
			"%.0f px 이상 (안 걸으면 캐시가 상했는지 못 잰다)" % WALK)
	_finish()

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
func _measure(phase: String) -> void:
	var tex: ViewportTexture = root.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.get_width() == 0:
		_fail("화면 [%s]" % phase, "텍스처가 비었다", "%s (--headless 로 띄웠나?)" % LOGICAL)
		return
	if img.get_width() != LOGICAL.x or img.get_height() != LOGICAL.y:
		_fail("화면 크기 [%s]" % phase, "%dx%d" % [img.get_width(), img.get_height()],
			"%dx%d" % [LOGICAL.x, LOGICAL.y])
		return
	_compare(img, phase)

## 화면의 점 하나하나를 월드 좌표로 되돌려 **그 칸의 색**과 맞춘다.
## 되돌리는 데 쓰는 것이 캔버스 변환이므로, 카메라가 어긋나 있으면 여기서 통째로 빨개진다.
func _compare(img: Image, phase: String) -> void:
	var inv := root.get_canvas_transform().affine_inverse()
	var center := Vector2(LOGICAL) * 0.5
	var n := 0
	var miss := 0
	var water := 0
	var worst := 0.0
	var first := ""
	for sy in range(STEP / 2, LOGICAL.y, STEP):
		for sx in range(STEP / 2, LOGICAL.x, STEP):
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
		_fail("화면이 월드와 다르다 [%s]" % phase, "%d / %d 점 (첫 어긋남: %s)" % [miss, n, first],
			"전부 일치 (허용 색차 %.1f/255)" % (TOL * 255.0))
	if wet < MIN_SHARE * 100.0 or wet > (1.0 - MIN_SHARE) * 100.0:
		_fail("해안이 화면에 없다 [%s]" % phase, "물 %.1f%% · 땅 %.1f%%" % [wet, 100.0 - wet],
			"각각 %.0f%% 이상 (한 지형만이면 색 판정이 공허하다)" % (MIN_SHARE * 100.0))
	if drawn <= 0 or drawn > MAX_TILES:
		_fail("그린 칸 수 [%s]" % phase, "%d 칸" % drawn,
			"1 .. %d 칸 (보이는 칸만 — 월드는 %d 칸이다)" % [MAX_TILES, WorldGen.SIZE * WorldGen.SIZE])

func _finish() -> void:
	print("DRAW %s (표본 간격 %d px · 중심 %.0f px 제외 · 서서 + 걷고 두 번)" % [
		"ok" if _bad == 0 else "FAIL %d개" % _bad, STEP, SKIP_BOX])
	if _main != null:
		_main.queue_free()
	quit(1 if _bad > 0 else 0)

func _fail(what: String, actual: String, expected: String) -> void:
	_bad += 1
	print("DRAW FAIL %s — 잰 값 %s · 기대 %s" % [what, actual, expected])
