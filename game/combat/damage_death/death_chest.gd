class_name DeathChest
extends Node2D
## 데스 상자 하나 — 페널티가 켜진 월드에서 죽은 자리에 떨어진다 (spec/08_combat/damage-death.md).
## 죽은 캐릭터(owner_id)만 열고 꺼낸다. 타이머가 0 이 되면 안의 아이템과 함께 사라진다.
## 창이 하나라도 열려 있는 동안은 타이머가 멈춘다. 다 꺼내 비면 바로 사라진다.
## 그림은 임시 색 네모다. 아트는 사람이 나중에 넣는다.

## 타이머가 끝나 아이템과 함께 사라졌다.
signal expired
## 주인이 다 꺼내 비었다 — 곧 사라진다.
signal emptied
## 안의 아이템이 바뀌었다.
signal changed

const COLOR := Color(0.45, 0.28, 0.15)
const SIZE := 10.0

## 죽은 캐릭터의 id (CharacterData.id).
var owner_id := ""
## 담긴 아이템 — [{"id", "count"}].
var items: Array = []
## 사라지기까지 남은 초.
var time_left := 0.0
## 이 상자를 보고 있는 창 수 — 0 보다 크면 타이머가 멈춘다.
var _viewers := 0
var _gone := false


static func create(owner: String, contents: Array, at: Vector2, seconds: float) -> DeathChest:
	var c := DeathChest.new()
	c.owner_id = owner
	c.items = clean_items(contents)
	c.position = at
	c.time_left = maxf(seconds, 0.0)
	return c


## 아이템 목록에서 빈칸 · 틀린 값을 뺀 사본.
static func clean_items(contents: Variant) -> Array:
	var out := []
	if contents is Array:
		for it in contents:
			if it is Dictionary and it.get("id") is String and not str(it.id).is_empty() \
					and (it.get("count") is int) and int(it.count) > 0:
				out.append({"id": it.id, "count": it.count})
	return out


func is_gone() -> bool:
	return _gone


func is_paused() -> bool:
	return _viewers > 0


## 이 캐릭터가 열 수 있나 — 죽은 본인만.
func can_open(who_id: String) -> bool:
	return not _gone and not who_id.is_empty() and who_id == owner_id


## 창이 열리고 닫힐 때 부른다 — 열린 창이 있는 동안 타이머가 멈춘다.
func set_viewing(on: bool) -> void:
	_viewers = maxi(_viewers + (1 if on else -1), 0)


## 타이머를 delta 초 흘린다. 창이 열려 있으면 흐르지 않는다.
func tick(delta: float) -> void:
	if _gone or is_paused() or delta <= 0.0:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		_vanish()
		expired.emit()


## i번 아이템을 가방으로 옮긴다. 주인이 아니면 아무것도 하지 않는다. 옮긴 개수.
func take(i: int, who_id: String, inventory: Inventory) -> int:
	if not can_open(who_id) or inventory == null or i < 0 or i >= items.size():
		return 0
	var it: Dictionary = items[i]
	var left := inventory.add(it)
	var moved := int(it.count) - left
	if left > 0:
		it["count"] = left
	else:
		items.remove_at(i)
	if moved > 0:
		changed.emit()
	_vanish_if_empty()
	return moved


## 전부 가방으로 옮긴다 (못 들어간 몫은 남는다). 주인이 아니면 0.
func take_all(who_id: String, inventory: Inventory) -> int:
	if not can_open(who_id):
		return 0
	var moved := 0
	for i in range(items.size() - 1, -1, -1):
		moved += take(i, who_id, inventory)
		if _gone:
			break
	return moved


func count_of(id: String) -> int:
	var total := 0
	for it in items:
		if it.id == id:
			total += int(it.count)
	return total


## 월드 저장 값.
func to_dict() -> Dictionary:
	return {"owner": owner_id, "pos": position, "items": items.duplicate(true), "left": time_left}


static func is_valid_dict(d: Variant) -> bool:
	return d is Dictionary and d.get("owner") is String and d.get("pos") is Vector2 \
		and d.get("items") is Array and (d.get("left") is float or d.get("left") is int)


static func from_dict(d: Dictionary, seconds_cap: float) -> DeathChest:
	return create(d.owner, d.items, d.pos, minf(float(d.left), seconds_cap))


func _vanish_if_empty() -> void:
	if not _gone and items.is_empty():
		_vanish()
		emptied.emit()


func _vanish() -> void:
	_gone = true
	items.clear()
	changed.emit()
	queue_free()


func _draw() -> void:
	var half := Vector2(SIZE, SIZE) / 2.0
	draw_rect(Rect2(-half, half * 2.0), COLOR)
