class_name Session
extends RefCounted
## 메뉴 화면 사이에 들고 다니는 값 — 고른 캐릭터 슬롯과 캐릭터, 저장소.
## 테스트는 store 를 임시 폴더의 SaveStore 로 바꿔 끼운다.

static var store := SaveStore.new()
## 고른(또는 새로 만들) 캐릭터 슬롯. 없으면 -1.
static var character_slot := -1
## 고른 캐릭터. 빈 슬롯을 골랐으면 null.
static var character: CharacterData = null


static func select_character(slot: int) -> void:
	character_slot = slot
	character = store.load_character(slot)


static func clear() -> void:
	character_slot = -1
	character = null
