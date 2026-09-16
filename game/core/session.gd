class_name Session
extends RefCounted
## 메뉴 화면 사이에 들고 다니는 값 — 고른 캐릭터 · 월드와 저장소.
## 테스트는 store 를 임시 폴더의 SaveStore 로 바꿔 끼운다.

static var store := SaveStore.new()
## 고른(또는 새로 만들) 캐릭터 슬롯. 없으면 -1.
static var character_slot := -1
## 고른 캐릭터. 빈 슬롯을 골랐으면 null.
static var character: CharacterData = null
## 고른 월드 id. 없으면 "".
static var world_id := ""
## 고른 월드. 없으면 null.
static var world: WorldData = null
## 들고 있는 월드의 서버장인가 — 월드를 만든 사람이 서버장이고, 혼자 할 때는 자기가 서버장이다.
## 남의 월드에 들어가는 길(리슨 서버)이 아직 없어 늘 참이다 — 손님 접속이 생기면 그 단계가 false 로 둔다.
static var is_host := true


static func select_character(slot: int) -> void:
	character_slot = slot
	character = store.load_character(slot)


static func select_world(id: String) -> void:
	world_id = id
	world = store.load_world(id)


## 캐릭터와 월드를 둘 다 들고 있나 — 게임에 들어갈 수 있나.
static func ready_to_play() -> bool:
	return character != null and world != null


## 들고 있는 캐릭터와 월드를 각자 자리에 저장한다. 둘 다 됐으면 OK.
static func save_all() -> Error:
	var result := OK
	if character != null:
		var err := store.save_character(character_slot, character)
		if err != OK:
			result = err
	if world != null:
		var err := store.save_world(world_id, world)
		if err != OK:
			result = err
	return result


static func clear_world() -> void:
	world_id = ""
	world = null
	is_host = true


static func clear() -> void:
	character_slot = -1
	character = null
	clear_world()
