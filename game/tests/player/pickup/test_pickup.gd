extends "res://tests/life/harvest/harvest_test_base.gd"
## G-004 4단계 — 떨어진 아이템 위를 지나가면 클릭 없이 가방에 들어가고, 가방이 차면 못 넣은 몫은 바닥에 남는다.

const MAX := InventoryConfig.STACK_MAX


func after_each() -> void:
	for action in [InputActions.MOVE_UP, InputActions.MOVE_DOWN, InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT]:
		Input.action_release(action)
	super.after_each()


func _fill_bag(game: GameScene, id: String) -> void:
	for i in InventoryConfig.BAG_SIZE:
		game.player().hotbar.inventory.set_slot(i, {"id": id, "count": MAX})


## 빈 칸 둘(드롭 자리, 설 자리)을 찾아 드롭을 놓고 옆 칸에 선다.
func _setup_drop(game: GameScene, item: Dictionary) -> Array:
	var found := _find(game, Deposit.NONE)
	_stand(game, found[1])
	var drop := DroppedItem.create(item, game.island_view().cell_center(found[0]))
	game.drops().add_child(drop)
	return [found[0], found[1], drop]


func _move_action(dir: Vector2i) -> StringName:
	match dir:
		Vector2i.LEFT: return InputActions.MOVE_LEFT
		Vector2i.RIGHT: return InputActions.MOVE_RIGHT
		Vector2i.UP: return InputActions.MOVE_UP
	return InputActions.MOVE_DOWN


## 드롭 칸 쪽으로 걸어서 드롭 칸 한가운데를 지나칠 때까지 걷는다.
func _walk_over(game: GameScene, from: Vector2i, to: Vector2i) -> void:
	var action := _move_action(to - from)
	var target := game.island_view().cell_center(to)
	Input.action_press(action)
	for i in 120:
		await wait_physics_frames(1)
		if game.player().global_position.distance_to(target) < 2.0:
			break
	Input.action_release(action)
	await wait_physics_frames(2)


func test_standing_next_to_a_drop_does_not_pick_it_up() -> void:
	var game := _enter()
	var s := _setup_drop(game, {"id": "wood", "count": 2})
	await wait_physics_frames(5)
	assert_true(is_instance_valid(s[2]) and s[2].get_parent() == game.drops(), "picked from a tile away")
	assert_eq(game.player().hotbar.inventory.count_of("wood"), 0)
	await _leave_physics_frame()


func test_walking_over_a_drop_picks_it_up_without_clicking() -> void:
	var game := _enter()
	var s := _setup_drop(game, {"id": "wood", "count": 2})
	var picks := []
	game.picker().picked.connect(func(id, amount, left): picks.append([id, amount, left]))
	await _walk_over(game, s[1], s[0])
	assert_false(Input.is_action_pressed(InputActions.USE), "no click was used")
	assert_eq(game.player().hotbar.inventory.count_of("wood"), 2)
	assert_eq(game.player().hotbar.item(1), {"id": "wood", "count": 2}, "first empty slot is hotbar 1")
	assert_eq(game.dropped_items().size(), 0, "drop must be gone from the ground")
	assert_eq(picks, [["wood", 2, 0]])
	assert_true(game.hotbar_view().slot_has_item(1), "hotbar view must show the picked item")
	await _leave_physics_frame()


func test_harvested_drop_is_picked_by_stepping_on_its_cell() -> void:
	var game := _enter()
	var found := _find(game, Deposit.STONE)
	_stand(game, found[1])
	_hold(game, PICKAXE)
	assert_gt(_swings_to_clear(game, found[0]), 0)
	assert_eq(_drops_at(game, found[0]).size(), 1)
	await _walk_over(game, found[1], found[0])
	assert_eq(_drops_at(game, found[0]).size(), 0)
	assert_eq(game.player().hotbar.inventory.count_of("stone"), _cfg().drop_count)
	await _leave_physics_frame()


func test_full_bag_leaves_the_drop_on_the_ground() -> void:
	var game := _enter()
	_fill_bag(game, "iron_ore")
	var s := _setup_drop(game, {"id": "wood", "count": 4})
	await _walk_over(game, s[1], s[0])
	var drops := _drops_at(game, s[0])
	assert_eq(drops.size(), 1, "drop must stay when the bag is full")
	if drops.size() == 1:
		assert_eq(drops[0].count(), 4)
	assert_eq(game.player().hotbar.inventory.count_of("wood"), 0)
	assert_eq(game.player().hotbar.inventory.count_of("iron_ore"), MAX * InventoryConfig.BAG_SIZE)
	await _leave_physics_frame()


func test_partly_full_bag_leaves_the_rest_and_saves_it() -> void:
	var game := _enter()
	_fill_bag(game, "iron_ore")
	game.player().hotbar.inventory.set_slot(InventoryConfig.BAG_SIZE - 1, {"id": "wood", "count": MAX - 2})
	var s := _setup_drop(game, {"id": "wood", "count": 5})
	await _walk_over(game, s[1], s[0])
	assert_eq(game.player().hotbar.inventory.count_of("wood"), MAX)
	var drops := _drops_at(game, s[0])
	assert_eq(drops.size(), 1, "the rest must stay on the ground")
	if drops.size() == 1:
		assert_eq(drops[0].count(), 3)
	# 남은 몫은 월드에, 주운 몫은 캐릭터에 저장된다.
	game.exit_to_menu()
	var world := Session.store.load_world(_world_id)
	var saved := world.drops.filter(func(d): return d["pos"].is_equal_approx(game.island_view().cell_center(s[0])))
	assert_eq(saved.size(), 1)
	if saved.size() == 1:
		assert_eq(int(saved[0]["count"]), 3)
	var c := Session.store.load_character(0)
	assert_eq(c.inventory[InventoryConfig.BAG_SIZE - 1], {"id": "wood", "count": MAX})
	await _leave_physics_frame()


func test_room_in_bag_later_picks_up_the_rest() -> void:
	var game := _enter()
	_fill_bag(game, "iron_ore")
	var s := _setup_drop(game, {"id": "wood", "count": 4})
	await _walk_over(game, s[1], s[0])
	assert_eq(_drops_at(game, s[0]).size(), 1)
	# 자리가 나면 그 위에 서 있는 동안 마저 줍는다.
	game.player().hotbar.inventory.set_slot(5, null)
	await wait_physics_frames(2)
	assert_eq(_drops_at(game, s[0]).size(), 0)
	assert_eq(game.player().hotbar.inventory.slot(5), {"id": "wood", "count": 4})
	await _leave_physics_frame()
