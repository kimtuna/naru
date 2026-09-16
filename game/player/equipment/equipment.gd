class_name Equipment
extends RefCounted
## 캐릭터의 장비 칸 — 칸마다 아이템 하나. 내용은 CharacterData.equipment 에 있다 (칸 이름 → 아이템 또는 null).
## 끼우면 가방에서 빠지고, 빼면 가방으로 돌아간다. 아이템은 {"id", "count": 1}.

signal changed

var character: CharacterData
var inventory: Inventory


func _init(bag: Inventory = null) -> void:
	inventory = bag if bag else Inventory.new()
	character = inventory.character


static func slot_of(item_id: String) -> String:
	return str(EquipmentConfig.ITEM_SLOTS.get(item_id, ""))


static func can_equip(item_id: String) -> bool:
	return not slot_of(item_id).is_empty()


## 칸에 낀 아이템. 비었거나 없는 칸이면 null.
func item(slot_name: String) -> Variant:
	var it = character.equipment.get(slot_name)
	return it if it is Dictionary else null


## 이 아이템을 어느 칸에든 끼고 있나.
func is_wearing(item_id: String) -> bool:
	var it = item(slot_of(item_id))
	return it != null and str(it.get("id", "")) == item_id


## 가방 bag_index 칸의 아이템 하나를 맞는 칸에 끼운다. 그 칸에 있던 것은 가방으로 돌아간다.
## 끼울 수 없는 아이템 · 빈칸 · 돌려놓을 자리가 없으면 아무것도 바꾸지 않고 false.
func equip_from_bag(bag_index: int) -> bool:
	var it = inventory.slot(bag_index)
	if not (it is Dictionary):
		return false
	var id := str(it.get("id", ""))
	var slot_name := slot_of(id)
	if slot_name.is_empty():
		return false
	var old = item(slot_name)
	# 한 개뿐이면 그 칸이 비어 돌려놓을 자리가 생긴다.
	if old != null and int(it.get("count", 0)) > 1 and not _bag_has_room(str(old.get("id", ""))):
		return false
	if not inventory.remove_at(bag_index, 1):
		return false
	character.equipment[slot_name] = {"id": id, "count": 1}
	if old != null:
		inventory.add(old)
	changed.emit()
	return true


## 칸의 아이템을 가방으로 돌려놓는다. 빈칸이거나 가방이 가득 차면 false.
func unequip(slot_name: String) -> bool:
	var old = item(slot_name)
	if old == null or not _bag_has_room(str(old.get("id", ""))):
		return false
	inventory.add(old)
	character.equipment[slot_name] = null
	changed.emit()
	return true


## 아이템 하나를 넣을 자리가 있나 — 같은 것이 덜 찬 칸이나 빈칸.
func _bag_has_room(id: String) -> bool:
	for i in inventory.size():
		var it = inventory.slot(i)
		if it == null:
			return true
		if str(it.get("id", "")) == id and int(it.get("count", 0)) < InventoryConfig.STACK_MAX:
			return true
	return false
