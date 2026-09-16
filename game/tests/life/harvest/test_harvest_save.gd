extends "res://tests/life/harvest/harvest_test_base.gd"
## G-004 3단계 — 바뀐 칸은 월드 저장에 남는다. 지형은 시드로 다시 만들고 바뀐 것만 저장한다.

const SEED := 777


func world_seed() -> int:
	return SEED


func _leave(game: GameScene) -> void:
	game.exit_to_menu()
	assert_eq(Screens.last_request, Screens.MAIN_MENU)
	Screens.last_request = ""
	game.free()
	await wait_process_frames(1)


func _harvest(game: GameScene, deposit: Deposit, tool: Dictionary) -> Vector2i:
	var found := _find(game, deposit)
	game.player().global_position = game.island_view().cell_center(found[1])
	game.player().hotbar.set_item(1, tool)
	game.player().hotbar.select(1)
	for i in 10:
		if game.island.deposit_at(found[0]) == Deposit.NONE:
			break
		game.harvester().swing(found[0])
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "setup: harvest failed")
	return found[0]


func test_harvested_cells_stay_empty_after_reentering() -> void:
	var game := _enter()
	var tree := _harvest(game, Deposit.TREE, AXE)
	var ore := _harvest(game, Deposit.IRON, PICKAXE)
	await _leave(game)

	var again := _enter()
	assert_eq(again.island.deposit_at(tree), Deposit.NONE, "felled tree must stay gone")
	assert_eq(again.island.deposit_at(ore), Deposit.NONE, "mined ore must stay gone")
	assert_false(again.island.is_blocked(tree))
	assert_true(again.island.is_removed(tree))
	# 나머지 칸은 시드가 만든 값 그대로다.
	var fresh := IslandGenerator.generate(SEED)
	var cells := 0
	for y in range(tree.y - 20, tree.y + 21):
		for x in range(tree.x - 20, tree.x + 21):
			var cell := Vector2i(x, y)
			if not again.island.has_cell(cell) or cell == tree or cell == ore:
				continue
			cells += 1
			assert_eq(again.island.deposit_at(cell), fresh.deposit_at(cell), "cell %s changed" % [cell])
			assert_eq(again.island.terrain_at(cell), fresh.terrain_at(cell))
	assert_gt(cells, 100)
	# 들어가서 한 번 더 나가도 그대로.
	await _leave(again)
	var third := _enter()
	assert_eq(third.island.deposit_at(tree), Deposit.NONE)
	assert_eq(third.island.deposit_at(ore), Deposit.NONE)


func test_world_save_holds_only_the_changes() -> void:
	var game := _enter()
	var tree := _harvest(game, Deposit.TREE, AXE)
	await _leave(game)
	var saved := Session.store.load_world(_world_id)
	assert_eq(saved.world_seed, SEED)
	assert_eq(saved.removed_cells.keys(), [tree], "only the harvested cell is stored")
	var d := saved.to_dict()
	for key in d:
		var v = d[key]
		if v is PackedByteArray or v is Array:
			assert_lt(v.size(), 10, "save must not hold the whole terrain (%s)" % key)


func test_drops_stay_on_the_ground_after_reentering() -> void:
	var game := _enter()
	var stone := _harvest(game, Deposit.STONE, PICKAXE)
	var center := game.island_view().cell_center(stone)
	await _leave(game)
	var again := _enter()
	var here := again.dropped_items().filter(func(x): return x.position.is_equal_approx(center))
	assert_eq(here.size(), 1)
	if here.size() == 1:
		assert_eq(here[0].item_id(), "stone")
		assert_gt(here[0].count(), 0)


func test_world_data_round_trip_keeps_changes() -> void:
	var w := WorldData.create("W", 5)
	w.removed_cells[Vector2i(3, 4)] = true
	w.removed_cells[Vector2i(10, 200)] = true
	w.drops.append({"id": "wood", "count": 2, "pos": Vector2(8, 24)})
	var back := WorldData.from_dict(w.to_dict())
	assert_eq(back.removed_cells, w.removed_cells)
	assert_eq(back.drops, w.drops)
	# 옛 저장(바뀐 것 없음)도 읽힌다.
	var old := WorldData.from_dict({"name": "O", "seed": 1, "created_at": 0})
	assert_eq(old.removed_cells.size(), 0)
	assert_eq(old.drops.size(), 0)


func test_lazy_island_applies_removed_marks_to_chunks_built_later() -> void:
	var gen := IslandGenerator.new(SEED)
	var full := IslandMap.new(gen)
	var target: Vector2i = _find_in(full, Deposit.TREE)[0]
	var marks := {target: true}
	var lazy := IslandMap.new(IslandGenerator.new(SEED), true, marks)
	assert_false(lazy.is_chunk_built(lazy.chunk_of(target)))
	assert_eq(lazy.deposit_at(target), Deposit.NONE)
	var changed := []
	lazy.cell_changed.connect(func(c): changed.append(c))
	var other: Vector2i = _find_in(full, Deposit.STONE)[0]
	assert_true(lazy.remove_deposit(other))
	assert_eq(changed, [other])
	assert_true(marks.has(other), "removal must land in the shared save marks")
	assert_false(lazy.remove_deposit(other), "already empty")
	assert_false(lazy.remove_deposit(lazy.spawn()), "nothing to remove on empty ground")
	assert_false(marks.has(lazy.spawn()))
