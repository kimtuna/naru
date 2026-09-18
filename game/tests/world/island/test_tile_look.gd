extends GutTest
## G-015 2단계 — 칸을 어떻게 그릴지 이웃 높이로 고른다 (평면 · 절벽 앞면 · 윗가장자리 · 옆면 · 경사) · 그림자.

const Look := TileLook.Look
const SEED := 20260916


## Dir 순서 (N, S, E, W, NE, NW, SE, SW) 의 이웃 높이.
func _around(n: int, s: int, e: int, w: int, ne := -1, nw := -1, se := -1, sw := -1) -> PackedInt32Array:
	return PackedInt32Array([n, s, e, w, n if ne < 0 else ne, n if nw < 0 else nw, s if se < 0 else se,
		s if sw < 0 else sw])


func test_cliff_with_higher_north_is_front() -> void:
	assert_eq(TileLook.pick(true, 1, _around(2, 1, 1, 1)), Look.CLIFF_FRONT)
	assert_eq(TileLook.pick(true, 1, _around(2, 0, 1, 1)), Look.CLIFF_FRONT)
	# 북쪽이 높으면 동 · 서가 높아도 앞면.
	assert_eq(TileLook.pick(true, 1, _around(2, 1, 2, 2)), Look.CLIFF_FRONT)


func test_cliff_with_higher_south_is_top_edge() -> void:
	assert_eq(TileLook.pick(true, 1, _around(1, 2, 1, 1)), Look.CLIFF_TOP)
	assert_eq(TileLook.pick(true, 1, _around(0, 2, 1, 2)), Look.CLIFF_TOP)


func test_cliff_with_only_east_or_west_higher_is_side() -> void:
	assert_eq(TileLook.pick(true, 1, _around(1, 1, 2, 1)), Look.CLIFF_SIDE)
	assert_eq(TileLook.pick(true, 1, _around(1, 1, 1, 2)), Look.CLIFF_SIDE)
	assert_eq(TileLook.pick(true, 1, _around(0, 0, 2, 1)), Look.CLIFF_SIDE, "남북이 낮아도 높은 이웃이 동쪽뿐이면 옆면")


func test_cliff_without_higher_neighbor_uses_lower_side() -> void:
	assert_eq(TileLook.pick(true, 2, _around(2, 1, 2, 2)), Look.CLIFF_FRONT, "남쪽이 낮다 = 보는 쪽으로 떨어지는 벽")
	assert_eq(TileLook.pick(true, 2, _around(1, 2, 2, 2)), Look.CLIFF_TOP)
	assert_eq(TileLook.pick(true, 2, _around(2, 2, 1, 2)), Look.CLIFF_SIDE)
	assert_eq(TileLook.pick(true, 2, _around(2, 2, 2, 2, 2, 2, 1, 2)), Look.CLIFF_FRONT, "남동 대각선만 낮다")
	assert_eq(TileLook.pick(true, 2, _around(2, 2, 2, 2, 2, 1, 2, 2)), Look.CLIFF_TOP, "북서 대각선만 낮다")


func test_non_cliff_is_flat_or_slope() -> void:
	assert_eq(TileLook.pick(false, 1, _around(1, 1, 1, 1)), Look.FLAT)
	assert_eq(TileLook.pick(false, 0, _around(1, 1, 0, 0)), Look.FLAT, "더 높은 이웃만 있으면 평면 (경사는 높은 쪽 칸)")
	assert_eq(TileLook.pick(false, 1, _around(1, 0, 1, 1)), Look.SLOPE)
	assert_eq(TileLook.pick(false, 1, _around(1, 1, 1, 1, 0)), Look.SLOPE, "대각선 아래도 경사")
	# 같은 이웃이어도 절벽이면 경사가 아니다.
	assert_ne(TileLook.pick(true, 1, _around(1, 0, 1, 1)), Look.SLOPE)


func test_shadow_falls_south_of_higher_ground() -> void:
	assert_true(TileLook.shadowed(false, 0, 1, Look.SLOPE), "북쪽이 높다")
	assert_true(TileLook.shadowed(false, 1, 1, Look.CLIFF_FRONT), "북쪽이 절벽 앞면 (벽 발치)")
	assert_false(TileLook.shadowed(false, 1, 1, Look.FLAT))
	assert_false(TileLook.shadowed(false, 1, 0, Look.FLAT), "북쪽이 낮으면 그림자 없음")
	assert_false(TileLook.shadowed(true, 0, 1, Look.CLIFF_FRONT), "절벽 칸 자신은 앞면으로 그린다")


func test_higher_top_is_brighter() -> void:
	for kind in IslandConfig.Terrain.values():
		for h in IslandConfig.load_default().max_height:
			var lo := TilePalette.top(kind, h)
			var hi := TilePalette.top(kind, h + 1)
			assert_gt(hi.get_luminance(), lo.get_luminance(), "지형 %d 높이 %d→%d" % [kind, h, h + 1])


func test_front_face_is_light_on_top_dark_below() -> void:
	var top := TilePalette.top(IslandConfig.Terrain.MOUNTAIN, 2)
	assert_gt(TilePalette.FRONT_BANDS, 1)
	for i in TilePalette.FRONT_BANDS - 1:
		assert_gt(TilePainter.front_band(top, i).get_luminance(), TilePainter.front_band(top, i + 1).get_luminance())
	assert_lt(TilePainter.front_band(top, 0).get_luminance(), top.get_luminance(), "벽은 윗면보다 어둡다")
	# 두 칸 높이 벽 — 아랫칸 맨 위 띠가 윗칸 맨 아래 띠보다 어둡다 (칸마다 다시 밝아지지 않는다).
	var n := TilePalette.FRONT_BANDS
	assert_gt(TilePainter.front_band(top, n - 1, n * 2).get_luminance(),
		TilePainter.front_band(top, n, n * 2).get_luminance())
	assert_lt(TilePalette.FRONT_FOOT_COLOR.get_luminance(),
		TilePainter.front_band(top, TilePalette.FRONT_BANDS - 1).get_luminance(), "발치 그림자가 가장 어둡다")
	assert_gt(TilePalette.SHADOW_COLOR.a, 0.0)


func test_slope_is_told_apart_from_cliff() -> void:
	var top := TilePalette.top(IslandConfig.Terrain.MOUNTAIN, 1)
	assert_gt(TilePalette.SLOPE_LINES, 0)
	# 경사는 윗면 색 그대로 + 밝은 줄, 절벽 앞면은 어두운 띠 — 색이 겹치지 않는다.
	assert_gt(top.lightened(TilePalette.SLOPE_LIGHTEN).get_luminance(), top.get_luminance())
	assert_lt(TilePainter.front_band(top, 0).get_luminance(), top.get_luminance())


## 시드 섬에서 — 절벽 칸의 모양이 지도의 이웃 높이 규칙과 맞고, 앞면 · 윗가장자리가 실제로 나오고,
## 높은 땅 남쪽에 그림자가 진다.
func test_island_cells_follow_rules() -> void:
	var map := IslandMap.new(IslandGenerator.new(SEED), true)
	var s := map.spawn()
	var seen := {}
	var shadows := 0
	for y in range(s.y - 48, s.y + 48):
		for x in range(s.x - 48, s.x + 48):
			var c := Vector2i(x, y)
			var look := TileLook.of(map, c)
			seen[look] = true
			var h := map.height_at(c)
			if map.is_cliff(c):
				assert_true(look in [Look.CLIFF_FRONT, Look.CLIFF_TOP, Look.CLIFF_SIDE])
				if map.height_at(c + Vector2i.UP) > h:
					assert_eq(look, Look.CLIFF_FRONT, "%s" % c)
				elif map.height_at(c + Vector2i.DOWN) > h:
					assert_eq(look, Look.CLIFF_TOP, "%s" % c)
			else:
				assert_true(look in [Look.FLAT, Look.SLOPE])
				if map.height_at(c + Vector2i.UP) > h:
					assert_true(TileLook.shadow_at(map, c), "높은 땅 남쪽 %s" % c)
					shadows += 1
	for want in [Look.FLAT, Look.SLOPE, Look.CLIFF_FRONT, Look.CLIFF_TOP]:
		assert_true(seen.has(want), "모양 %d 이 스폰 둘레에 있다" % want)
	assert_gt(shadows, 0)
