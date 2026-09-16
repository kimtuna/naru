class_name Hotbar
extends RefCounted
## 핫바 — 캐릭터 인벤토리의 앞 HOTBAR_SIZE 칸과 고른 칸.
## 내용과 고른 칸은 CharacterData 에 있다 — 캐릭터와 함께 저장되고 어느 월드에나 따라간다.
## 인벤토리 목록의 번호가 곧 칸 번호다. 목록이 짧거나 null 인 칸은 빈칸.
## 칸 번호는 화면 · 숫자키와 같게 1부터 센다.

signal changed

var character: CharacterData


func _init(owner_character: CharacterData = null) -> void:
	character = owner_character if owner_character else CharacterData.new()


func size() -> int:
	return InventoryConfig.HOTBAR_SIZE


## 고른 칸 번호 (1 ~ size()).
func selected() -> int:
	return clampi(character.hotbar_selected, 1, size())


## 칸을 고른다. 범위 밖이면 무시하고 false.
func select(slot: int) -> bool:
	if not _valid(slot):
		return false
	if character.hotbar_selected != slot:
		character.hotbar_selected = slot
		changed.emit()
	return true


## 칸의 아이템. 빈칸이면 null.
func item(slot: int) -> Variant:
	var i := slot - 1
	if not _valid(slot) or i >= character.inventory.size():
		return null
	return character.inventory[i]


## 칸에 아이템을 넣는다 (null 이면 비운다). 범위 밖이면 false.
func set_item(slot: int, value: Variant) -> bool:
	if not _valid(slot):
		return false
	var i := slot - 1
	if character.inventory.size() <= i:
		if value == null:
			return true
		character.inventory.resize(i + 1)
	character.inventory[i] = value
	changed.emit()
	return true


## 손에 든 것 — 고른 칸의 아이템. 빈칸이면 null (빈손).
func held_item() -> Variant:
	return item(selected())


func _valid(slot: int) -> bool:
	return slot >= 1 and slot <= size()
