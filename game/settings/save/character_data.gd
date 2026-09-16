class_name CharacterData
extends RefCounted
## 캐릭터 저장 값. 어느 월드에나 데려간다 (spec/11_multiplayer/character-world.md).

## 캐릭터를 가리키는 id — 만들 때 한 번 정하고 저장에 남는다. 데스 상자의 주인을 이것으로 가린다.
var id := ""
var name := ""
## 외형 칸 이름 → 고른 값. 칸 목록은 캐릭터 생성 단계에서 정한다.
var appearance: Dictionary = {}
## 칸별 아이템 — 번호가 곧 칸 번호(0부터), null 은 빈칸. 앞 칸들이 핫바다 (Hotbar).
## 아이템은 {"id": 이름, "count": 개수}. 새 캐릭터는 빈손이다.
var inventory: Array = []
## 장비 칸 이름 → 낀 아이템 {"id", "count"} 또는 null (Equipment). 칸 목록은 EquipmentConfig.SLOTS.
var equipment: Dictionary = {}
## 핫바에서 고른 칸 (1부터).
var hotbar_selected := 1


func _init() -> void:
	id = new_id()


static func new_id() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"appearance": appearance.duplicate(true),
		"inventory": inventory.duplicate(true),
		"equipment": equipment.duplicate(true),
		"hotbar_selected": hotbar_selected,
	}


static func from_dict(d: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	# id 가 없는 옛 저장은 새로 만든 id 를 쓴다 — 다음 저장에 남는다.
	if d.get("id") is String and not str(d["id"]).is_empty():
		c.id = d["id"]
	c.name = str(d.get("name", ""))
	c.appearance = (d.get("appearance", {}) as Dictionary).duplicate(true)
	c.inventory = (d.get("inventory", []) as Array).duplicate(true)
	# 장비가 없던 옛 저장은 빈 장비다.
	var equipped = d.get("equipment", {})
	c.equipment = (equipped as Dictionary).duplicate(true) if equipped is Dictionary else {}
	var selected = d.get("hotbar_selected", 1)
	c.hotbar_selected = selected if selected is int else 1
	return c
