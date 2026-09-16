class_name Crop
extends RefCounted
## 밭에 심은 작물 하나 — 자란 날 수와 오늘 물을 받았는지.

## 다 자라면 떨어지는 아이템 id.
var id := ""
## 물을 받고 넘긴 날 수.
var days := 0
## 오늘 물을 받았나 — 날이 넘어가면 마른다.
var watered := false


static func create(crop_id: String) -> Crop:
	var c := Crop.new()
	c.id = crop_id
	return c


func is_ripe(grow_days: int) -> bool:
	return days >= grow_days


## 날이 넘어갔다 — 물을 받았으면 하루 자라고, 물은 마른다.
func pass_day(grow_days: int) -> bool:
	var grew := watered and not is_ripe(grow_days)
	if grew:
		days += 1
	watered = false
	return grew


## 월드 저장 값.
func to_dict(cell: Vector2i) -> Dictionary:
	return {"cell": cell, "id": id, "days": days, "watered": watered}


## 저장 값이 올바른가 — 칸과 id 가 있어야 한다.
static func is_valid_dict(d: Variant) -> bool:
	return d is Dictionary and d.get("cell") is Vector2i and d.get("id") is String and d.id != "" \
		and (d.get("days", 0) is int or d.get("days", 0) is float) and d.get("watered", false) is bool


static func from_dict(d: Dictionary) -> Crop:
	var c := Crop.create(str(d.id))
	c.days = maxi(int(d.get("days", 0)), 0)
	c.watered = bool(d.get("watered", false))
	return c
