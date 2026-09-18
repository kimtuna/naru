class_name TilePainter
extends RefCounted
## 칸 하나를 색 네모로 그린다 — 모양은 TileLook, 색 · 세기는 TilePalette (3/4 시점 시험, G-015).

const Look := TileLook.Look


## ci 의 at 에 한 변 t 픽셀로 cell 을 그린다 (자원 네모는 빼고).
static func paint(ci: CanvasItem, at: Vector2, t: float, map: IslandMap, cell: Vector2i) -> void:
	var height := map.height_at(cell)
	var around := TileLook.around_of(map, cell)
	var look := TileLook.pick(map.is_cliff(cell), height, around)
	var top := TilePalette.top(map.terrain_at(cell), height)
	var rect := Rect2(at, Vector2(t, t))
	match look:
		Look.CLIFF_FRONT:
			_front(ci, rect, top, _front_run(map, cell, Vector2i.UP), _front_run(map, cell, Vector2i.DOWN))
		Look.CLIFF_TOP:
			ci.draw_rect(rect, top)
			ci.draw_rect(Rect2(at, Vector2(t, TilePalette.TOP_EDGE_PX)), TilePalette.TOP_EDGE_COLOR)
		Look.CLIFF_SIDE:
			ci.draw_rect(rect, top.darkened(TilePalette.SIDE_DARKEN))
			var side := TileLook.side_of(height, around)
			var w := t * TilePalette.SIDE_STRIP
			var x := at.x + (t - w if side > 0 else 0.0)
			if side != 0:
				ci.draw_rect(Rect2(x, at.y, w, t), top.darkened(TilePalette.SIDE_STRIP_DARKEN))
		Look.SLOPE:
			ci.draw_rect(rect, top)
			for i in TilePalette.SLOPE_LINES:
				var y := at.y + t * (i + 1) / (TilePalette.SLOPE_LINES + 1)
				ci.draw_rect(Rect2(at.x, y, t, TilePalette.SLOPE_LINE_PX), top.lightened(TilePalette.SLOPE_LIGHTEN))
		_:
			ci.draw_rect(rect, top)
	if TileLook.shadow_at(map, cell):
		ci.draw_rect(Rect2(at, Vector2(t, t * TilePalette.SHADOW_DEPTH)), TilePalette.SHADOW_COLOR)


## 앞면 — 위가 밝고 아래로 어두워지는 가로 띠. 여러 칸 높이 벽이면 벽 전체에 걸쳐 어두워진다
## (above · below = 위 · 아래로 이어진 앞면 칸 수). 벽이 여기서 끝나면 발치에 그림자.
static func _front(ci: CanvasItem, rect: Rect2, top: Color, above: int, below: int) -> void:
	var n := TilePalette.FRONT_BANDS
	var total := (above + 1 + below) * n
	var band := rect.size.y / n
	for i in n:
		ci.draw_rect(Rect2(rect.position.x, rect.position.y + band * i, rect.size.x, band),
			front_band(top, above * n + i, total))
	if below == 0:
		var foot := rect.size.y * TilePalette.FRONT_FOOT
		ci.draw_rect(Rect2(rect.position.x, rect.end.y - foot, rect.size.x, foot), TilePalette.FRONT_FOOT_COLOR)


## 벽 전체 띠 total 개 가운데 i 번째 (0 = 맨 위) 색 — 아래로 갈수록 어둡다.
static func front_band(top: Color, i: int, total := TilePalette.FRONT_BANDS) -> Color:
	var k := float(i) / maxf(total - 1, 1)
	return top.darkened(lerpf(TilePalette.FRONT_TOP_DARKEN, TilePalette.FRONT_BOTTOM_DARKEN, k))


## step 쪽으로 이어진 앞면 칸 수 (FRONT_RUN_MAX 까지만 본다).
static func _front_run(map: IslandMap, cell: Vector2i, step: Vector2i) -> int:
	var n := 0
	var c := cell + step
	while n < TilePalette.FRONT_RUN_MAX and map.has_cell(c) and TileLook.of(map, c) == Look.CLIFF_FRONT:
		n += 1
		c += step
	return n
