extends TestBase

## 월드 그리기의 순수 계산을 잰다. 값의 출처는 NUMBERS 9절.
##
## **여기는 「무엇을 그려야 하나」만 본다.** 「화면에 실제로 그렇게 그려졌나」는
## tools/tests/measure_window.gd 가 구운 픽셀을 월드 칸과 맞춰서 잰다 —
## main.gd 가 아예 안 그려도 이 파일은 전부 초록으로 남는다.

const SEED := 20260914
const SCREEN := Vector2(960, 540)

## ── 어느 칸을 그리나 ─────────────────────────────────────────────────

## 화면 구석 네 점이 전부 범위 안에 있어야 한다. 한 줄이라도 모자라면
## 화면 가장자리에 배경색 띠가 생긴다.
func test_range_covers_every_corner_of_the_view() -> void:
	var t := PlayerMotion.TILE
	for origin in [Vector2(0, 0), Vector2(6168, 6168), Vector2(-100.5, 37.2), Vector2(5688, 5898)]:
		var view := Rect2(origin, SCREEN)
		var r := WorldView.tile_range(view)
		for corner in [view.position, view.position + Vector2(view.size.x, 0),
				view.position + Vector2(0, view.size.y), view.position + view.size]:
			var c := Vector2i(floori(corner.x / t), floori(corner.y / t))
			check(r.has_point(c), "구석 %s 의 칸 %s 이 범위 %s 밖이다 (view %s)" % [corner, c, r, view])

## **보이는 칸만 그린다**는 주장은 이 비율이 전부다.
func test_visible_tiles_are_a_sliver_of_the_world() -> void:
	var n := WorldView.tile_count(Rect2(Vector2(6168, 6168), SCREEN))
	var whole := WorldGen.SIZE * WorldGen.SIZE
	check(n <= 273, "보이는 칸 — 잰 값 %d · 기대 273 이하 (20x11.25 화면 + 경계 한 줄)" % n)
	check(n * 200 < whole, "보이는 칸 %d 이 월드 %d 칸에 비해 안 작다" % [n, whole])

## 칸 경계에 딱 맞는 화면. 가로는 960/48 = 20 이 딱 떨어져서 오른쪽 끝이 다음 칸의
## 첫 픽셀에 닿으므로 21 줄이고, 세로는 540/48 = 11.25 라 안 닿아서 12 줄이다.
## **최대는 여기가 아니라 어긋난 화면이다** — 그때 21 x 13 = 273 이 된다.
func test_range_on_exact_tile_boundary() -> void:
	var t := PlayerMotion.TILE
	var r := WorldView.tile_range(Rect2(Vector2(10 * t, 4 * t), SCREEN))
	eq(r.position, Vector2i(10, 4), "칸 경계에 맞춘 화면의 시작 칸")
	eq(r.size, Vector2i(21, 12), "칸 경계에 맞춘 화면의 칸 수 (20+1 가로 · 11.25→12 세로)")

## 음수 좌표에서 0 쪽으로 반올림하면 칸 하나가 통째로 어긋난다.
func test_negative_coords_floor_not_truncate() -> void:
	var r := WorldView.tile_range(Rect2(Vector2(-10.0, -10.0), Vector2(20.0, 20.0)))
	eq(r.position, Vector2i(-1, -1), "음수 화면의 시작 칸")
	eq(r.size, Vector2i(2, 2), "음수 화면의 칸 수")

## ── 그 칸이 무슨 색인가 ──────────────────────────────────────────────

## **색이 곧 지형이다.** 흔들기는 세 채널에 같은 양을 더하므로 이 부등식은
## 절대 안 뒤집힌다 — 뒤집히면 물처럼 보이는 땅이 생긴다.
func test_water_is_blue_and_land_is_green() -> void:
	var bad_water := 0
	var bad_land := 0
	var n := 0
	for y in range(0, WorldGen.SIZE, 3):
		for x in range(0, WorldGen.SIZE, 3):
			n += 1
			var c := WorldView.color_at(SEED, x, y)
			if WorldGen.tile_at(SEED, x, y) == WorldGen.WATER:
				if not (c.b > c.g and c.g > c.r):
					bad_water += 1
			elif not (c.g > c.r and c.r > c.b):
				bad_land += 1
	eq(bad_water, 0, "b > g > r 이 아닌 물 칸 (표본 %d)" % n)
	eq(bad_land, 0, "g > r > b 가 아닌 땅 칸 (표본 %d)" % n)

## 월드 밖은 감쇠가 1.25 로 포화해서 높이가 -0.25 를 못 넘는다 — **분기가 아니라
## 부등식이 보장한다** (WorldView.DEEP_AT 머리말). 그 부등식을 여기서 잰다.
func test_outside_world_is_deep() -> void:
	for p in [Vector2i(-1, 100), Vector2i(100, -1), Vector2i(WorldGen.SIZE, 100),
			Vector2i(100, WorldGen.SIZE), Vector2i(-500, -500)]:
		eq(WorldView.terrain_color(SEED, p.x, p.y), WorldView.DEEP, "월드 밖 %s 의 지형색" % p)

## 해수면 바로 위가 밝아야 해안선이 눈에 보인다.
func test_shore_is_brighter_than_inland() -> void:
	check(WorldView.SHORE.get_luminance() > WorldView.GRASS.get_luminance(),
		"해안 %.3f 이 안쪽 풀밭 %.3f 보다 안 밝다" % [
			WorldView.SHORE.get_luminance(), WorldView.GRASS.get_luminance()])
	check(WorldView.SHOAL.get_luminance() > WorldView.DEEP.get_luminance(),
		"얕은 바다 %.3f 가 깊은 바다 %.3f 보다 안 밝다" % [
			WorldView.SHOAL.get_luminance(), WorldView.DEEP.get_luminance()])

## 같은 씨앗은 같은 색이다 — 월드가 재현 가능해도 그림이 매번 다르면 소용없다.
func test_same_seed_is_same_color() -> void:
	var diff := 0
	for i in 200:
		var x := 60 + i
		if WorldView.color_at(SEED, x, 128) != WorldView.color_at(SEED, x, 128):
			diff += 1
	eq(diff, 0, "같은 씨앗·같은 칸인데 다른 색")

## **화면이 거의 단색이면 안 된다.** shot.sh 의 `--max-flat` 이 재는 것과 같은 성질을,
## 픽셀을 굽지 않고 칸 수준에서 먼저 잡는다. 스폰 주변은 전부 땅이라 여기가 제일 위험하다.
func test_a_screenful_is_not_flat() -> void:
	var spawn := WorldGen.spawn_tile()
	var counts := {}
	var n := 0
	for ty in range(spawn.y - 6, spawn.y + 7):
		for tx in range(spawn.x - 10, spawn.x + 11):
			var k := WorldView.color_at(SEED, tx, ty).to_html(false)
			counts[k] = int(counts.get(k, 0)) + 1
			n += 1
	var top := 0
	for k in counts:
		top = maxi(top, int(counts[k]))
	var flat := 100.0 * top / n
	check(counts.size() >= 100,
		"스폰 한 화면의 색 수 — 잰 값 %d개 / %d칸 · 기대 100개 이상" % [counts.size(), n])
	check(flat <= 10.0, "스폰 한 화면의 가장 넓은 한 색 — 잰 값 %.1f%% · 기대 10%% 이하" % flat)
