class_name CraftStation
extends StaticBody2D
## 설치된 제작대 하나 — 한 칸을 차지하고 몸을 막는다 (spec/05_craft/crafting-stations.md).
## 그림은 임시 색 네모다. 아트는 사람이 나중에 넣는다.

## 임시 색 — 제작대 종류마다.
const COLORS := {
	"workbench": Color(0.72, 0.5, 0.25),
}

## 제작 장소 id — 레시피의 station 값이자 설치하는 아이템 id.
var station_id := ""
var cell := Vector2i.ZERO
var tile_px := 16


static func create(id: String, at_cell: Vector2i, tile: int) -> CraftStation:
	var s := CraftStation.new()
	s.station_id = id
	s.cell = at_cell
	s.tile_px = tile
	s.name = "Station_%d_%d" % [at_cell.x, at_cell.y]
	s.position = Vector2(at_cell * tile)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile, tile)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = shape.size / 2.0
	s.add_child(col)
	return s


## 월드 저장에 넣는 값.
func to_dict() -> Dictionary:
	return {"id": station_id, "cell": cell}


func _draw() -> void:
	var t := Vector2(tile_px, tile_px)
	draw_rect(Rect2(Vector2.ONE, t - Vector2.ONE * 2.0), COLORS.get(station_id, Color.MAGENTA))
