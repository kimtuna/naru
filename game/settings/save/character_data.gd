class_name CharacterData
extends RefCounted
## 캐릭터 저장 값. 어느 월드에나 데려간다 (spec/11_multiplayer/character-world.md).

var name := ""
## 외형 칸 이름 → 고른 값. 칸 목록은 캐릭터 생성 단계에서 정한다.
var appearance: Dictionary = {}
## 아이템 목록. 아이템 구조가 생기기 전까지는 빈 목록.
var inventory: Array = []


func to_dict() -> Dictionary:
	return {
		"name": name,
		"appearance": appearance.duplicate(true),
		"inventory": inventory.duplicate(true),
	}


static func from_dict(d: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.name = str(d.get("name", ""))
	c.appearance = (d.get("appearance", {}) as Dictionary).duplicate(true)
	c.inventory = (d.get("inventory", []) as Array).duplicate(true)
	return c
