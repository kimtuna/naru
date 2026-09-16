class_name Inventory
extends RefCounted
## 캐릭터의 가방 — InventoryConfig.BAG_SIZE 칸. 내용은 CharacterData.inventory 에 있다.
## 칸 번호는 0부터 (저장 목록의 번호 그대로). 앞 칸들이 핫바다 (Hotbar 는 1부터 센다).
## 아이템은 {"id": 이름, "count": 개수}. 목록이 짧거나 null 인 칸은 빈칸.

signal changed

var character: CharacterData


func _init(owner_character: CharacterData = null) -> void:
	character = owner_character if owner_character else CharacterData.new()


func size() -> int:
	return InventoryConfig.BAG_SIZE


## i번 칸의 아이템. 빈칸 · 범위 밖이면 null.
func slot(i: int) -> Variant:
	if i < 0 or i >= mini(size(), character.inventory.size()):
		return null
	return character.inventory[i]


## i번 칸에 넣는다 (null 이면 비운다). 범위 밖이면 false.
func set_slot(i: int, value: Variant) -> bool:
	if i < 0 or i >= size():
		return false
	if character.inventory.size() <= i:
		if value == null:
			return true
		character.inventory.resize(i + 1)
	character.inventory[i] = value
	changed.emit()
	return true


## 아이템을 넣는다 — 같은 것이 든 칸을 먼저 채우고, 남으면 앞쪽 빈칸부터. 못 넣은 개수를 돌려준다.
func add(item: Dictionary) -> int:
	var id := str(item.get("id", ""))
	var left := int(item.get("count", 0))
	if id.is_empty() or left <= 0:
		return maxi(left, 0)
	var start := left
	for i in size():
		var it = slot(i)
		if left > 0 and it is Dictionary and str(it.get("id", "")) == id:
			left -= _fill(it, left)
	for i in size():
		if left > 0 and slot(i) == null:
			var it := {"id": id, "count": 0}
			if character.inventory.size() <= i:
				character.inventory.resize(i + 1)
			character.inventory[i] = it
			left -= _fill(it, left)
	if left != start:
		changed.emit()
	return left


## 이 아이템 id 를 뒤쪽 칸부터 count 개 뺀다. 모자라면 하나도 빼지 않고 false.
func remove(id: String, count: int) -> bool:
	if count <= 0:
		return true
	if count_of(id) < count:
		return false
	var left := count
	for i in range(size() - 1, -1, -1):
		var it = slot(i)
		if left > 0 and it is Dictionary and str(it.get("id", "")) == id:
			var take := mini(int(it.get("count", 0)), left)
			left -= take
			it["count"] = int(it.get("count", 0)) - take
			if it["count"] <= 0:
				character.inventory[i] = null
	changed.emit()
	return true


## 이 아이템 id 의 개수 합.
func count_of(id: String) -> int:
	var total := 0
	for i in size():
		var it = slot(i)
		if it is Dictionary and str(it.get("id", "")) == id:
			total += int(it.get("count", 0))
	return total


func _fill(it: Dictionary, want: int) -> int:
	var put := clampi(InventoryConfig.STACK_MAX - int(it.get("count", 0)), 0, want)
	it["count"] = int(it.get("count", 0)) + put
	return put
