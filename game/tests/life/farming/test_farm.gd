extends "res://tests/craft/stations/station_test_base.gd"
## G-007 1단계 — 삽 · 개간 · 되돌리기.
## 삽을 들고 맨땅에 우클릭하면 밭이 되고, 밭에 다시 우클릭하면 맨땅으로 돌아간다. 삽 레시피가 있다.

const SHOVEL := {"id": "shovel", "count": 1}


## 스폰에 서서 오른쪽 맨땅 칸.
func _bare_next_to_spawn(game: GameScene) -> Vector2i:
	var here := game.island.spawn()
	_stand(game, here)
	var cell := here + Vector2i.RIGHT
	assert_true(game.farm().is_bare(cell), "setup: the cell next to spawn is bare ground")
	return cell


# --- 개간 · 되돌리기 ---

func test_shovel_right_click_tills_then_reverts() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, SHOVEL)
	assert_false(game.farm().is_tilled(cell))
	await _right_click_cell(game, cell)
	assert_true(game.farm().is_tilled(cell), "right click with a shovel on bare ground tills it")
	assert_eq(game.farm().tilled_cells(), [cell] as Array[Vector2i])
	assert_eq(game.swinger().swing_count, 0, "tilling is not a swing")
	assert_eq(_held(game), SHOVEL, "the shovel is not used up")
	await _right_click_cell(game, cell)
	assert_false(game.farm().is_tilled(cell), "right click on a field turns it back to bare ground")
	assert_true(game.farm().is_bare(cell))
	await _right_click_cell(game, cell)
	assert_true(game.farm().is_tilled(cell), "and it can be tilled again")
	await _leave_physics_frame()


func test_only_the_shovel_tills() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	for item in [null, AXE, PICKAXE, {"id": "wood", "count": 3}]:
		_hold(game, item)
		await _right_click_cell(game, cell)
		assert_false(game.farm().is_tilled(cell), "%s does not till" % str(item))
	await _leave_physics_frame()


func test_other_items_do_not_revert_a_field() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, SHOVEL)
	await _right_click_cell(game, cell)
	for item in [null, AXE]:
		_hold(game, item)
		await _right_click_cell(game, cell)
	assert_true(game.farm().is_tilled(cell), "only the shovel turns a field back")
	await _leave_physics_frame()


func test_left_click_with_shovel_does_not_till() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, SHOVEL)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(cell))
	_click(true, screen_mid)
	await wait_physics_frames(2)
	_click(false, screen_mid)
	await wait_physics_frames(1)
	assert_false(game.farm().is_tilled(cell), "left click swings the shovel, it does not till")
	assert_gt(game.swinger().swing_count, 0)
	await _leave_physics_frame()


func test_resource_cells_are_not_bare_ground() -> void:
	_hide_gut_layer()
	var game := _enter()
	_hold(game, SHOVEL)
	for deposit in [Deposit.TREE, Deposit.STONE]:
		var found := _find(game, deposit)
		_stand(game, found[1])
		await _right_click_cell(game, found[0])
		assert_false(game.farm().is_tilled(found[0]), "a %s cell is not tilled" % deposit)
		assert_eq(game.island.deposit_at(found[0]), deposit, "the resource stays")
	assert_false(game.farm().dig(Vector2i(-1, -1)), "outside the island")
	assert_eq(game.farm().tilled_cells().size(), 0)
	await _leave_physics_frame()


func test_out_of_reach_does_nothing() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, SHOVEL)
	var reach := _swing_cfg().reach_px(game.island_view().tile_px())
	var far := here + Vector2i(ceili(reach / game.island_view().tile_px()) + 1, 0)
	assert_true(game.farm().is_bare(far), "setup: far cell is bare")
	await _right_click_cell(game, far)
	assert_false(game.farm().is_tilled(far), "a cell out of reach is not tilled")
	game.farm().till(far)
	await _right_click_cell(game, far)
	assert_true(game.farm().is_tilled(far), "a field out of reach is not reverted")
	await _leave_physics_frame()


func test_station_and_field_do_not_share_a_cell() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := await _place_next_to_spawn(game)
	assert_false(game.farm().is_bare(cell), "a station cell is not bare ground")
	assert_false(game.farm().dig(cell))
	assert_false(game.farm().is_tilled(cell))
	var other := cell + Vector2i.DOWN
	_hold(game, SHOVEL)
	assert_true(game.farm().dig(other))
	_hold(game, _bench())
	assert_false(game.stations().try_place(other), "a station is not placed on a field")
	assert_null(game.stations().station_at(other))
	await _leave_physics_frame()


func test_field_stops_regrowth_around_it_until_reverted() -> void:
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, SHOVEL)
	assert_true(game.farm().dig(cell))
	assert_true(game.regrowth().structures.has(cell), "a field is a structure for regrowth")
	assert_true(game.farm().dig(cell))
	assert_false(game.regrowth().structures.has(cell), "reverting removes it")
	await _leave_physics_frame()


func test_fields_are_saved_with_the_world() -> void:
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, SHOVEL)
	assert_true(game.farm().dig(cell))
	game.store_world_state()
	assert_eq(game.world.tilled, [cell])
	assert_eq(Session.store.save_world(_world_id, game.world), OK)
	game.free()
	var again := _enter()
	assert_true(again.farm().is_tilled(cell), "a field is still there after loading")
	assert_true(again.regrowth().structures.has(cell))
	var copy := WorldData.from_dict(again.world.to_dict())
	assert_eq(copy.tilled, [cell])
	assert_eq(WorldData.from_dict({"tilled": [cell, "x", 3]}).tilled, [cell], "bad entries are dropped")
	await _leave_physics_frame()


# --- 삽 레시피 ---

func test_shovel_has_a_recipe_made_from_raw_materials() -> void:
	var book := RecipeBook.load_default()
	var r := book.recipe_for(Farm.SHOVEL)
	assert_false(r.is_empty(), "no recipe makes a shovel")
	assert_eq(r.output.id, "shovel")
	assert_gt(r.output.count, 0)
	assert_true(book.stations.has(r.station))
	var d := book.depth_of(Farm.SHOVEL)
	assert_gt(d, 0, "shovel cannot be made from raw materials")
	assert_true(d <= RecipeBook.MAX_DEPTH)


func test_shovel_recipe_is_craftable_with_its_materials() -> void:
	var book := RecipeBook.load_default()
	var r := book.recipe_for(Farm.SHOVEL)
	var inv := Inventory.new(CharacterData.new())
	assert_false(book.has_materials(r, inv), "empty bag cannot make a shovel")
	for it in r.inputs:
		inv.add({"id": it.id, "count": it.count})
	assert_true(book.has_materials(r, inv))
