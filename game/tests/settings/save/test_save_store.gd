extends GutTest
## G-002 1단계 — 캐릭터 · 월드 분리 저장 수용 기준.

var _root := ""
var _store: SaveStore


func before_each() -> void:
	# 실제 사용자 저장(user://saves)과 겹치지 않는 OS 임시 폴더.
	_root = OS.get_temp_dir().path_join("naru_test_saves_%d_%d" % [Time.get_ticks_usec(), randi()])
	_store = SaveStore.new(_root)


func after_each() -> void:
	_remove_tree(_root)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for dir in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(dir))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _character(char_name: String) -> CharacterData:
	var c := CharacterData.new()
	c.name = char_name
	c.appearance = {"body": 2, "hair": 5, "hair_color": 1}
	return c


func test_character_roundtrip_keeps_values() -> void:
	var c := _character("나루")
	assert_eq(_store.save_character(1, c), OK)
	var loaded := SaveStore.new(_root).load_character(1)
	assert_not_null(loaded)
	if loaded:
		assert_eq(loaded.name, "나루")
		assert_eq(loaded.appearance, {"body": 2, "hair": 5, "hair_color": 1})
		assert_eq(loaded.inventory, [])
		assert_eq(loaded.to_dict(), c.to_dict())


func test_character_inventory_survives_roundtrip() -> void:
	var c := _character("A")
	c.inventory = [{"id": "stone", "count": 3}]
	var slot := _store.create_character(c)
	assert_eq(_store.load_character(slot).inventory, [{"id": "stone", "count": 3}])


func test_world_roundtrip_keeps_values() -> void:
	var w := WorldData.create("첫 섬", 9007199254740993)  # 2^53+1 — float 로 바뀌면 깨진다
	assert_gt(w.created_at, 0)
	var id := _store.create_world(w)
	assert_ne(id, "")
	var loaded := SaveStore.new(_root).load_world(id)
	assert_not_null(loaded)
	if loaded:
		assert_eq(loaded.name, "첫 섬")
		assert_eq(loaded.world_seed, 9007199254740993)
		assert_eq(loaded.created_at, w.created_at)
		assert_eq(loaded.to_dict(), w.to_dict())


func test_character_and_world_are_stored_separately() -> void:
	_store.create_character(_character("A"))
	var id := _store.create_world(WorldData.create("X", 1))
	assert_eq(_store.character_slots(), [0])
	assert_eq(_store.world_ids(), PackedStringArray([id]))
	assert_eq(_store.delete_world(id), OK)
	assert_not_null(_store.load_character(0), "deleting a world must not touch characters")


func test_character_slots_are_three() -> void:
	assert_eq(SaveConfig.CHARACTER_SLOTS, 3)
	assert_eq(_store.save_character(3, _character("X")), ERR_PARAMETER_RANGE_ERROR)
	assert_eq(_store.save_character(-1, _character("X")), ERR_PARAMETER_RANGE_ERROR)


func test_fourth_character_is_rejected() -> void:
	assert_eq(_store.create_character(_character("A")), 0)
	assert_eq(_store.create_character(_character("B")), 1)
	assert_eq(_store.create_character(_character("C")), 2)
	assert_eq(_store.create_character(_character("D")), -1)
	assert_eq(_store.character_slots(), [0, 1, 2])
	for slot in 3:
		assert_eq(_store.load_character(slot).name, ["A", "B", "C"][slot], "existing kept")


func test_freed_slot_can_be_reused() -> void:
	for n in ["A", "B", "C"]:
		_store.create_character(_character(n))
	assert_eq(_store.delete_character(1), OK)
	assert_eq(_store.create_character(_character("D")), 1)
	assert_eq(_store.load_character(1).name, "D")


func test_delete_character() -> void:
	var slot := _store.create_character(_character("A"))
	assert_true(_store.has_character(slot))
	assert_eq(_store.delete_character(slot), OK)
	assert_false(_store.has_character(slot))
	assert_null(_store.load_character(slot))
	assert_eq(_store.character_slots(), [])
	assert_eq(_store.delete_character(slot), ERR_DOES_NOT_EXIST)


func test_delete_world() -> void:
	var a := _store.create_world(WorldData.create("X", 1))
	var b := _store.create_world(WorldData.create("Y", 2))
	assert_ne(a, b)
	assert_eq(_store.delete_world(a), OK)
	assert_false(_store.has_world(a))
	assert_null(_store.load_world(a))
	assert_eq(_store.world_ids(), PackedStringArray([b]))
	assert_eq(_store.delete_world(a), ERR_DOES_NOT_EXIST)


func test_default_location_is_under_user() -> void:
	assert_true(SaveConfig.DEFAULT_ROOT.begins_with("user://"))
	assert_eq(SaveStore.new().root, SaveConfig.DEFAULT_ROOT)


func test_tests_do_not_touch_user_saves() -> void:
	assert_false(_store.root.begins_with("user://"))
	var real := SaveStore.new()
	var before_slots := real.character_slots()
	var before_worlds := real.world_ids()
	_store.create_character(_character("A"))
	_store.create_world(WorldData.create("X", 1))
	assert_true(FileAccess.file_exists(_root.path_join("characters/slot_0.sav")))
	assert_eq(real.character_slots(), before_slots)
	assert_eq(real.world_ids(), before_worlds)


func test_bad_world_id_is_rejected() -> void:
	assert_eq(_store.save_world("../escape", WorldData.create("X", 1)), ERR_INVALID_PARAMETER)
	assert_eq(_store.save_world("", WorldData.create("X", 1)), ERR_INVALID_PARAMETER)
	assert_false(_store.has_world("../escape"))
