extends GutTest
## G-014 1단계 — 신발 칸과 스파이크.
## 캐릭터에 신발 칸이 있고, 스파이크를 끼우고 뺄 수 있다. 캐릭터 저장에 남는다. 스파이크 레시피가 있다.

const FEET := EquipmentConfig.FEET
const SPIKES := EquipmentConfig.SPIKES

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_equip_%d_%d" % [Time.get_ticks_usec(), randi()])


func after_each() -> void:
	for dir in [SaveConfig.CHARACTER_DIR, SaveConfig.WORLD_DIR]:
		var path := _root.path_join(dir)
		if DirAccess.dir_exists_absolute(path):
			for file in DirAccess.get_files_at(path):
				DirAccess.remove_absolute(path.path_join(file))
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(_root)


func _equipment_with(items: Array) -> Equipment:
	var c := CharacterData.new()
	c.inventory = items.duplicate(true)
	return Equipment.new(Inventory.new(c))


# --- 신발 칸 ---

func test_character_has_feet_slot_and_spikes_go_there() -> void:
	assert_has(EquipmentConfig.SLOTS, FEET)
	assert_eq(Equipment.slot_of(SPIKES), FEET)
	assert_false(Equipment.can_equip("wood"), "plain items are not equipment")
	var eq := _equipment_with([])
	assert_null(eq.item(FEET), "new character wears nothing")
	assert_false(eq.is_wearing(SPIKES))


func test_equip_spikes_moves_one_from_bag_to_feet() -> void:
	var eq := _equipment_with([{"id": "wood", "count": 3}, {"id": SPIKES, "count": 2}])
	watch_signals(eq)
	assert_true(eq.equip_from_bag(1))
	assert_eq(eq.item(FEET), {"id": SPIKES, "count": 1})
	assert_true(eq.is_wearing(SPIKES))
	assert_eq(eq.inventory.count_of(SPIKES), 1, "one pair left in the bag")
	assert_eq(eq.character.equipment[FEET], {"id": SPIKES, "count": 1}, "must live in the character")
	assert_signal_emitted(eq, "changed")


func test_unequip_returns_spikes_to_bag() -> void:
	var eq := _equipment_with([{"id": SPIKES, "count": 1}])
	assert_true(eq.equip_from_bag(0))
	assert_eq(eq.inventory.count_of(SPIKES), 0)
	assert_true(eq.unequip(FEET))
	assert_null(eq.item(FEET))
	assert_false(eq.is_wearing(SPIKES))
	assert_eq(eq.inventory.count_of(SPIKES), 1)
	assert_false(eq.unequip(FEET), "nothing left to take off")


func test_cannot_equip_non_equipment_or_empty_slot() -> void:
	var eq := _equipment_with([{"id": "wood", "count": 3}])
	assert_false(eq.equip_from_bag(0))
	assert_false(eq.equip_from_bag(5))
	assert_eq(eq.inventory.count_of("wood"), 3)
	assert_null(eq.item(FEET))


func test_unequip_fails_when_bag_full() -> void:
	var items := []
	for i in InventoryConfig.BAG_SIZE:
		items.append({"id": "stone", "count": InventoryConfig.STACK_MAX})
	var eq := _equipment_with(items)
	eq.character.equipment[FEET] = {"id": SPIKES, "count": 1}
	assert_false(eq.unequip(FEET))
	assert_eq(eq.item(FEET), {"id": SPIKES, "count": 1}, "spikes are not lost")


func test_equip_swaps_worn_pair_back_into_bag() -> void:
	var eq := _equipment_with([{"id": SPIKES, "count": 1}, {"id": SPIKES, "count": 1}])
	assert_true(eq.equip_from_bag(0))
	assert_true(eq.equip_from_bag(1))
	assert_eq(eq.item(FEET), {"id": SPIKES, "count": 1})
	assert_eq(eq.inventory.count_of(SPIKES), 1, "old pair came back, nothing duplicated or lost")


# --- 저장 ---

func test_worn_spikes_survive_character_save() -> void:
	var eq := _equipment_with([{"id": SPIKES, "count": 1}])
	eq.character.name = "등반가"
	assert_true(eq.equip_from_bag(0))
	var store := SaveStore.new(_root)
	var slot := store.create_character(eq.character)
	assert_ne(slot, -1)
	var loaded := SaveStore.new(_root).load_character(slot)
	assert_not_null(loaded)
	var again := Equipment.new(Inventory.new(loaded))
	assert_true(again.is_wearing(SPIKES), "spikes still on after load")
	assert_eq(again.inventory.count_of(SPIKES), 0)
	# 뺀 상태도 남는다.
	assert_true(again.unequip(FEET))
	assert_eq(store.save_character(slot, loaded), OK)
	var loaded2 := SaveStore.new(_root).load_character(slot)
	assert_false(Equipment.new(Inventory.new(loaded2)).is_wearing(SPIKES))
	assert_eq(Inventory.new(loaded2).count_of(SPIKES), 1)


func test_old_save_without_equipment_loads_empty() -> void:
	var c := CharacterData.from_dict({"name": "옛", "inventory": []})
	assert_eq(c.equipment, {})
	assert_null(Equipment.new(Inventory.new(c)).item(FEET))


# --- 레시피 ---

func test_spikes_have_a_recipe_within_depth() -> void:
	var book := RecipeBook.load_default()
	var r := book.recipe_for(SPIKES)
	assert_false(r.is_empty(), "no recipe makes spikes")
	assert_true(book.stations.has(r.get("station", "")))
	assert_between(book.depth_of(SPIKES), 1, RecipeBook.MAX_DEPTH)
	assert_ne(tr("ITEM_SPIKES"), "ITEM_SPIKES", "spikes name is translated")
