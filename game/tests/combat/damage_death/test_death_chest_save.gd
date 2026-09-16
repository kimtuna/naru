extends "res://tests/combat/damage_death/death_chest_test_base.gd"
## G-009 3단계 — 데스 상자와 남은 시간이 월드 저장에 남는다.


func test_chests_and_time_left_survive_leaving_and_reentering() -> void:
	var game := _enter()
	var inv := _fill_bag(game)
	var first := _die_at(game, Vector2(64, 0))
	inv.add({"id": "wheat", "count": 2})
	var second := _die_at(game, Vector2(0, 64))
	var owner := game.character.id
	game.death_chests().advance(600.0)
	game.exit_to_menu()
	await wait_process_frames(1)

	var saved := Session.store.load_world(_world_id)
	assert_eq(saved.death_chests.size(), 2, "both chests are in the world save")
	var again := _enter()
	assert_eq(again.character.id, owner, "character id survives the save")
	var chests := again.death_chests().all()
	assert_eq(chests.size(), 2)
	assert_eq(chests[0].position, first)
	assert_eq(chests[1].position, second)
	for c in chests:
		assert_eq(c.owner_id, owner)
		assert_almost_eq(c.time_left, _chest_seconds() - 600.0, 0.5, "time left is kept")
	assert_eq(chests[0].count_of("axe"), 1)
	assert_eq(chests[0].count_of("stone"), 3)
	assert_eq(chests[0].count_of("wood"), 7)
	assert_eq(chests[1].count_of("wheat"), 2)
	assert_true(_bag_is_empty(again.player().hotbar.inventory), "emptied bag is saved too")

	_stand_by(again, chests[1])
	assert_true(again.death_chests().open(chests[1], again.character.id), "owner can still open after reload")
	assert_eq(again.death_chest_view().take_all(), 2)
	assert_eq(again.player().hotbar.inventory.count_of("wheat"), 2)

	again.death_chests().advance(_chest_seconds())
	again.store_world_state()
	assert_eq(again.world.death_chests.size(), 0, "vanished chests are not saved")


func test_expired_chest_is_gone_after_reload() -> void:
	var game := _enter()
	_fill_bag(game)
	_die_at(game, Vector2(64, 0))
	game.death_chests().advance(_chest_seconds())
	game.exit_to_menu()
	await wait_process_frames(1)
	assert_eq(Session.store.load_world(_world_id).death_chests.size(), 0)
	assert_eq(_enter().death_chests().all().size(), 0)


func test_world_data_round_trip_and_broken_entries() -> void:
	var w := WorldData.create("섬", 3)
	w.death_chests = [{"owner": "abc", "pos": Vector2(10, 20), "items": [WOOD], "left": 99.5}]
	var id := Session.store.create_world(w)
	var loaded := Session.store.load_world(id)
	assert_eq(loaded.death_chests.size(), 1)
	assert_eq(loaded.death_chests[0].owner, "abc")
	assert_eq(loaded.death_chests[0].pos, Vector2(10, 20))
	assert_eq(loaded.death_chests[0].items, [WOOD])
	assert_eq(loaded.death_chests[0].left, 99.5)
	var broken := WorldData.from_dict({"death_chests": [{"owner": 3}, "x", {"owner": "a", "pos": Vector2.ZERO}]})
	assert_eq(broken.death_chests.size(), 0, "broken entries are dropped")
	assert_eq(WorldData.from_dict({}).death_chests.size(), 0, "old saves have no chests")
	Session.store.delete_world(id)


func test_old_character_save_without_id_gets_one_that_sticks() -> void:
	var c := CharacterData.from_dict({"name": "옛"})
	assert_false(c.id.is_empty())
	assert_eq(CharacterData.from_dict(c.to_dict()).id, c.id)
