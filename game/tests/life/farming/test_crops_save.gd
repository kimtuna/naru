extends "res://tests/life/farming/crop_test_base.gd"
## G-007 2단계 — 밭 · 작물 상태가 월드 저장에 남는다. 씨앗 · 물뿌리개를 얻는 법이 있다.


# --- 저장 ---

func test_fields_and_crops_are_saved_with_the_world() -> void:
	var game := _enter()
	var cell := _planted(game)
	var empty := cell + Vector2i.DOWN
	assert_true(game.farm().dig(empty))
	_hold(game, _can())
	assert_true(game.farm().water(cell))
	_next_day(game)
	assert_true(game.farm().water(cell))
	game.store_world_state()
	assert_eq(game.world.crops, [{"cell": cell, "id": _farm_cfg().crop_id, "days": 1, "watered": true}])
	assert_eq(Session.store.save_world(_world_id, game.world), OK)
	game.free()
	var again := _enter()
	assert_true(again.farm().is_tilled(cell))
	assert_true(again.farm().is_tilled(empty))
	assert_null(again.farm().crop_at(empty))
	var crop := again.farm().crop_at(cell)
	assert_not_null(crop, "the crop is still there after loading")
	assert_eq(crop.id, _farm_cfg().crop_id)
	assert_eq(crop.days, 1, "growth is kept")
	assert_true(crop.watered, "today's water is kept")
	for day in _farm_cfg().grow_days - 1:
		_next_day(again)
		again.farm().water(cell)
	assert_true(again.farm().is_ripe(cell), "keeps growing after loading")
	await _leave_physics_frame()


func test_ripe_crop_is_saved() -> void:
	var game := _enter()
	var cell := _planted(game)
	_hold(game, _can())
	for day in _farm_cfg().grow_days:
		game.farm().water(cell)
		_next_day(game)
	game.store_world_state()
	assert_eq(Session.store.save_world(_world_id, game.world), OK)
	game.free()
	var again := _enter()
	assert_true(again.farm().is_ripe(cell), "a ripe crop stays ripe after loading")
	_stand(again, again.island.spawn())
	assert_true(again.farm().harvest(cell))
	assert_eq(_wheat_drops(again, cell).size(), 1)
	await _leave_physics_frame()


func test_crop_save_entries_are_checked() -> void:
	var cell := Vector2i(3, 4)
	var good := {"cell": cell, "id": "wheat", "days": 2, "watered": false}
	var w := WorldData.from_dict({"tilled": [cell], "crops": [good, "x", {"cell": cell}, {"id": "wheat"},
		{"cell": cell, "id": ""}, {"cell": cell, "id": "wheat", "days": "a"}]})
	assert_eq(w.crops, [good], "bad entries are dropped")
	assert_eq(WorldData.from_dict(w.to_dict()).crops, [good])
	assert_eq(WorldData.from_dict({}).crops, [])


func test_crop_without_a_field_is_not_loaded() -> void:
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	game.farm().load_crops([{"cell": cell, "id": "wheat", "days": 1, "watered": false}])
	assert_null(game.farm().crop_at(cell), "a crop needs a field")
	await _leave_physics_frame()


# --- 씨앗 · 물뿌리개를 얻는 법 ---

func test_seeds_and_watering_can_have_recipes() -> void:
	var book := RecipeBook.load_default()
	for id in [_farm_cfg().seed_id, _farm_cfg().watering_can_id]:
		var r := book.recipe_for(id)
		assert_false(r.is_empty(), "no recipe makes " + id)
		if r.is_empty():
			continue
		assert_gt(r.output.count, 0)
		var d := book.depth_of(id)
		assert_gt(d, 0, id + " cannot be made from raw materials")
		assert_true(d <= RecipeBook.MAX_DEPTH)
		var inv := Inventory.new(CharacterData.new())
		for it in r.inputs:
			inv.add({"id": it.id, "count": it.count})
		assert_true(book.has_materials(r, inv))
	assert_eq(book.recipe_for(_farm_cfg().seed_id).station, WORKBENCH, "seeds are made at the workbench")
	assert_ne(tr("ITEM_WHEAT_SEED"), "ITEM_WHEAT_SEED", "seed name is translated")
