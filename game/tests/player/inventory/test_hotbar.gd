extends GutTest
## G-003 4단계 — 핫바 모델: 칸 고르기 · 손에 든 것 · 내용은 캐릭터 인벤토리에 있고 저장 후에도 그대로.

var _root := ""


func after_each() -> void:
	if _root != "":
		for dir in [SaveConfig.CHARACTER_DIR, SaveConfig.WORLD_DIR]:
			var path := _root.path_join(dir)
			if DirAccess.dir_exists_absolute(path):
				for file in DirAccess.get_files_at(path):
					DirAccess.remove_absolute(path.path_join(file))
				DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(_root)
		_root = ""


func _store() -> SaveStore:
	_root = OS.get_temp_dir().path_join("naru_test_hotbar_%d_%d" % [Time.get_ticks_usec(), randi()])
	return SaveStore.new(_root)


func test_every_hotbar_slot_has_a_number_key() -> void:
	assert_gt(InventoryConfig.HOTBAR_SIZE, 0)
	assert_lte(InventoryConfig.HOTBAR_SIZE, InputActions.HOTBAR_ACTION_COUNT)
	for n in range(1, InventoryConfig.HOTBAR_SIZE + 1):
		assert_true(InputMap.has_action(InputActions.hotbar_action(n)), "no key for slot %d" % n)


func test_new_character_holds_nothing() -> void:
	var bar := Hotbar.new(CharacterData.new())
	assert_eq(bar.selected(), 1)
	for n in range(1, bar.size() + 1):
		assert_null(bar.item(n), "slot %d not empty" % n)
	assert_null(bar.held_item())


func test_select_changes_held_item() -> void:
	var c := CharacterData.new()
	c.inventory = [{"id": "axe", "count": 1}, null, {"id": "stone", "count": 5}]
	var bar := Hotbar.new(c)
	assert_eq(bar.held_item(), {"id": "axe", "count": 1})
	assert_true(bar.select(3))
	assert_eq(bar.selected(), 3)
	assert_eq(bar.held_item(), {"id": "stone", "count": 5})
	assert_true(bar.select(2))
	assert_null(bar.held_item(), "empty slot must mean empty hand")
	assert_true(bar.select(bar.size()))
	assert_null(bar.held_item(), "slot past the stored list is empty")


func test_select_out_of_range_is_ignored() -> void:
	var bar := Hotbar.new(CharacterData.new())
	bar.select(2)
	for bad in [0, -1, bar.size() + 1]:
		assert_false(bar.select(bad), "accepted slot %d" % bad)
		assert_eq(bar.selected(), 2)


func test_hotbar_contents_live_in_character_inventory() -> void:
	var c := CharacterData.new()
	var bar := Hotbar.new(c)
	watch_signals(bar)
	assert_true(bar.set_item(3, {"id": "wood", "count": 2}))
	assert_signal_emitted(bar, "changed")
	assert_eq(c.inventory.size(), 3)
	assert_eq(c.inventory[2], {"id": "wood", "count": 2})
	assert_null(c.inventory[0])
	bar.select(3)
	assert_eq(c.hotbar_selected, 3)
	# 인벤토리를 바로 고쳐도 핫바가 같은 것을 본다.
	c.inventory[0] = {"id": "shovel", "count": 1}
	assert_eq(bar.item(1), {"id": "shovel", "count": 1})
	assert_false(bar.set_item(bar.size() + 1, {"id": "x", "count": 1}))


func test_hotbar_survives_save_and_load() -> void:
	var store := _store()
	var c := CharacterData.new()
	c.name = "A"
	var bar := Hotbar.new(c)
	bar.set_item(1, {"id": "axe", "count": 1})
	bar.set_item(4, {"id": "stone", "count": 7})
	bar.select(4)
	var slot := store.create_character(c)
	assert_ne(slot, -1)

	var loaded := Hotbar.new(store.load_character(slot))
	assert_eq(loaded.selected(), 4)
	assert_eq(loaded.held_item(), {"id": "stone", "count": 7})
	for n in range(1, loaded.size() + 1):
		assert_eq(loaded.item(n), bar.item(n), "slot %d differs" % n)


func test_old_save_without_selection_loads() -> void:
	var c := CharacterData.from_dict({"name": "old", "appearance": {}, "inventory": [{"id": "a", "count": 1}]})
	assert_eq(c.hotbar_selected, 1)
	assert_eq(Hotbar.new(c).held_item(), {"id": "a", "count": 1})
	var bad := CharacterData.from_dict({"hotbar_selected": "x"})
	assert_eq(bad.hotbar_selected, 1)
