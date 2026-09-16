class_name Hotbar
extends RefCounted
## 핫바 — 캐릭터 인벤토리의 앞 HOTBAR_SIZE 칸과 고른 칸.
## 내용과 고른 칸은 CharacterData 에 있다 — 캐릭터와 함께 저장되고 어느 월드에나 따라간다.
## 칸 내용은 Inventory 가 다룬다 — 핫바 N번 칸은 가방 N-1번 칸이다.
## 칸 번호는 화면 · 숫자키와 같게 1부터 센다.

## 고른 칸이나 가방 내용이 바뀌면 알린다.
signal changed

var character: CharacterData
## 같은 캐릭터의 가방 — 줍기가 여기에 넣으면 핫바 화면도 바뀐다.
var inventory: Inventory


func _init(owner_character: CharacterData = null) -> void:
	character = owner_character if owner_character else CharacterData.new()
	inventory = Inventory.new(character)
	inventory.changed.connect(changed.emit)


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
	return inventory.slot(slot - 1) if _valid(slot) else null


## 칸에 아이템을 넣는다 (null 이면 비운다). 범위 밖이면 false.
func set_item(slot: int, value: Variant) -> bool:
	return _valid(slot) and inventory.set_slot(slot - 1, value)


## 손에 든 것 — 고른 칸의 아이템. 빈칸이면 null (빈손).
func held_item() -> Variant:
	return item(selected())


func _valid(slot: int) -> bool:
	return slot >= 1 and slot <= size()
