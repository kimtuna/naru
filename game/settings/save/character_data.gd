class_name CharacterData
extends RefCounted
## 캐릭터 저장 값. 어느 월드에나 데려간다 (spec/11_multiplayer/character-world.md).

var name := ""
## 외형 칸 이름 → 고른 값. 칸 목록은 캐릭터 생성 단계에서 정한다.
var appearance: Dictionary = {}
## 칸별 아이템 — 번호가 곧 칸 번호(0부터), null 은 빈칸. 앞 칸들이 핫바다 (Hotbar).
## 아이템은 {"id": 이름, "count": 개수}. 새 캐릭터는 빈손이다.
var inventory: Array = []
## 핫바에서 고른 칸 (1부터).
var hotbar_selected := 1


func to_dict() -> Dictionary:
	return {
		"name": name,
		"appearance": appearance.duplicate(true),
		"inventory": inventory.duplicate(true),
		"hotbar_selected": hotbar_selected,
	}


static func from_dict(d: Dictionary) -> CharacterData:
	var c := CharacterData.new()
	c.name = str(d.get("name", ""))
	c.appearance = (d.get("appearance", {}) as Dictionary).duplicate(true)
	c.inventory = (d.get("inventory", []) as Array).duplicate(true)
	var selected = d.get("hotbar_selected", 1)
	c.hotbar_selected = selected if selected is int else 1
	return c
