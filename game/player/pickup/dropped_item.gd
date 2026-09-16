class_name DroppedItem
extends Node2D
## 바닥에 떨어진 아이템 하나 (spec/02_player/pickup.md). 줍기는 다음 단계가 붙인다.

## 임시 색 — 아트는 사람이 나중에 넣는다.
const COLORS := {
	"wood": Color(0.6, 0.4, 0.2),
	"stone": Color(0.7, 0.7, 0.72),
	"ore": Color(0.95, 0.75, 0.2),
}
const SIZE := 6.0

## {"id": 이름, "count": 개수}
var item: Dictionary = {}


static func create(item_value: Dictionary, pos: Vector2) -> DroppedItem:
	var d := DroppedItem.new()
	d.item = item_value.duplicate(true)
	d.position = pos
	return d


func item_id() -> String:
	return str(item.get("id", ""))


func count() -> int:
	return int(item.get("count", 0))


## 월드 저장에 넣는 값.
func to_dict() -> Dictionary:
	return {"id": item_id(), "count": count(), "pos": position}


func _draw() -> void:
	var half := Vector2(SIZE, SIZE) / 2.0
	draw_rect(Rect2(-half, half * 2.0), COLORS.get(item_id(), Color.MAGENTA))
