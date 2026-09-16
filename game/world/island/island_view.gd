class_name IslandView
extends Node2D
## 섬을 화면에 — 카메라가 보는 곳 둘레의 덩어리만 만들고, 멀어진 덩어리는 치운다.
## 섬 바깥은 벽으로 막는다. 칸 (x, y) 는 픽셀 (x, y) × tile_px 에서 시작한다.

## 이 노드 둘레를 보이는 곳으로 삼는다 (보통 플레이어).
var follow: Node2D
var map: IslandMap
var config: IslandConfig
var _chunks := {}


func setup(island: IslandMap) -> void:
	map = island
	config = island.generator.config
	map.cell_changed.connect(_on_cell_changed)
	_build_border()


func tile_px() -> int:
	return config.tile_px


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * tile_px()


func cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell * tile_px()), Vector2(tile_px(), tile_px()))


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / tile_px()).floor())


func chunk_node(chunk: Vector2i) -> IslandChunk:
	return _chunks.get(chunk)


func chunk_count() -> int:
	return _chunks.size()


func _physics_process(_delta: float) -> void:
	if map and follow:
		update_around(follow.global_position)


## 화면 절반 크기 (월드 픽셀). 카메라 확대를 반영한다.
func visible_half_extent() -> Vector2:
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var cam := vp.get_camera_2d()
	if cam:
		size /= cam.zoom
	return size / 2.0


## center 둘레 (화면 + 여유) 를 덮는 덩어리를 만들고, 한 덩어리 넘게 벗어난 덩어리를 치운다.
func update_around(center: Vector2) -> void:
	if map == null:
		return
	var half := visible_half_extent() + Vector2.ONE * config.view_margin_px
	var span := float(map.chunk_size * tile_px())
	var lo := Vector2i(((center - half) / span).floor())
	var hi := Vector2i(((center + half) / span).floor())
	for key in _chunks.keys():
		if key.x < lo.x - 1 or key.y < lo.y - 1 or key.x > hi.x + 1 or key.y > hi.y + 1:
			_chunks[key].queue_free()
			_chunks.erase(key)
	for cy in range(lo.y, hi.y + 1):
		for cx in range(lo.x, hi.x + 1):
			var key := Vector2i(cx, cy)
			if map.has_chunk(key) and not _chunks.has(key):
				var node := IslandChunk.new()
				node.setup(map, key, tile_px())
				add_child(node)
				_chunks[key] = node


func _on_cell_changed(cell: Vector2i) -> void:
	var node := chunk_node(map.chunk_of(cell))
	if node:
		node.refresh()


## 섬 밖으로 못 나가게 네 변에 벽.
func _build_border() -> void:
	var body := StaticBody2D.new()
	body.name = "Border"
	add_child(body)
	var side := float(map.size * tile_px())
	var thick := float(tile_px() * 4)
	for r in [
		Rect2(-thick, -thick, side + thick * 2.0, thick),
		Rect2(-thick, side, side + thick * 2.0, thick),
		Rect2(-thick, 0.0, thick, side),
		Rect2(side, 0.0, thick, side),
	]:
		var shape := RectangleShape2D.new()
		shape.size = r.size
		var col := CollisionShape2D.new()
		col.shape = shape
		col.position = r.get_center()
		body.add_child(col)
