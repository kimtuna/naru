extends GutTest
## G-004 4단계 — 가방에 넣기: 같은 것부터 쌓고, 빈칸을 쓰고, 가득 차면 못 넣은 개수를 돌려준다.

const MAX := InventoryConfig.STACK_MAX


func _full_of(id: String) -> CharacterData:
	var c := CharacterData.new()
	for i in InventoryConfig.BAG_SIZE:
		c.inventory.append({"id": id, "count": MAX})
	return c


func test_new_inventory_is_empty_and_has_bag_size_slots() -> void:
	var inv := Inventory.new()
	assert_eq(inv.size(), InventoryConfig.BAG_SIZE)
	assert_gt(inv.size(), InventoryConfig.HOTBAR_SIZE, "bag must be bigger than the hotbar")
	for i in inv.size():
		assert_null(inv.slot(i))


func test_add_to_empty_goes_to_first_slot() -> void:
	var inv := Inventory.new()
	assert_eq(inv.add({"id": "wood", "count": 3}), 0)
	assert_eq(inv.slot(0), {"id": "wood", "count": 3})
	assert_eq(inv.character.inventory[0], {"id": "wood", "count": 3}, "must live in the character")


func test_add_stacks_onto_same_item_before_using_empty_slot() -> void:
	var c := CharacterData.new()
	c.inventory = [null, {"id": "stone", "count": 1}, null, {"id": "wood", "count": 2}]
	var inv := Inventory.new(c)
	assert_eq(inv.add({"id": "wood", "count": 5}), 0)
	assert_eq(inv.slot(3), {"id": "wood", "count": 7})
	assert_null(inv.slot(0), "must not open a new stack while one has room")
	assert_eq(inv.count_of("wood"), 7)


func test_overflowing_stack_spills_into_first_empty_slot() -> void:
	var c := CharacterData.new()
	c.inventory = [{"id": "iron_ore", "count": MAX - 2}]
	var inv := Inventory.new(c)
	assert_eq(inv.add({"id": "iron_ore", "count": 5}), 0)
	assert_eq(inv.slot(0), {"id": "iron_ore", "count": MAX})
	assert_eq(inv.slot(1), {"id": "iron_ore", "count": 3})


func test_full_inventory_returns_everything() -> void:
	var inv := Inventory.new(_full_of("stone"))
	var changes := [0]
	inv.changed.connect(func(): changes[0] += 1)
	assert_eq(inv.add({"id": "wood", "count": 4}), 4)
	assert_eq(inv.add({"id": "stone", "count": 1}), 1, "full stacks take nothing")
	assert_eq(inv.count_of("wood"), 0)
	assert_eq(changes[0], 0, "nothing changed, no signal")


func test_nearly_full_inventory_returns_the_rest() -> void:
	var c := _full_of("stone")
	c.inventory[InventoryConfig.BAG_SIZE - 1] = {"id": "wood", "count": MAX - 2}
	var inv := Inventory.new(c)
	assert_eq(inv.add({"id": "wood", "count": 5}), 3)
	assert_eq(inv.count_of("wood"), MAX)


func test_hotbar_shows_what_the_inventory_got() -> void:
	var bar := Hotbar.new()
	var changes := [0]
	bar.changed.connect(func(): changes[0] += 1)
	bar.inventory.add({"id": "wood", "count": 2})
	assert_eq(bar.item(1), {"id": "wood", "count": 2})
	assert_eq(bar.held_item(), {"id": "wood", "count": 2})
	assert_eq(changes[0], 1, "hotbar must hear inventory changes")


func test_slots_past_the_bag_are_rejected() -> void:
	var inv := Inventory.new()
	assert_false(inv.set_slot(InventoryConfig.BAG_SIZE, {"id": "wood", "count": 1}))
	assert_false(inv.set_slot(-1, {"id": "wood", "count": 1}))
	assert_null(inv.slot(InventoryConfig.BAG_SIZE))
