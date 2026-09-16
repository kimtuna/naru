extends "res://tests/life/harvest/harvest_test_base.gd"
## G-004 3단계 — 좌클릭 채취 → 바닥에 떨어짐.
## 겨눈 칸 + 손에 든 것이 동작을 정하고, 손이 닿아야 하고, 칸은 비고 아이템이 떨어진다.


# --- 맞는 조합: 칸이 비고 해당 아이템이 떨어진다 ---

func test_matching_tool_clears_cell_and_drops_item() -> void:
	var game := _enter()
	var cases := [
		[AXE, Deposit.TREE, "wood"],
		[PICKAXE, Deposit.STONE, "stone"],
		[PICKAXE, Deposit.ORE, "ore"],
		[null, Deposit.TREE, "wood"],
		[null, Deposit.STONE, "stone"],
	]
	var used: Array = []
	for c in cases:
		var found := _find(game, c[1], used)
		var cell: Vector2i = found[0]
		used.append(cell)
		_stand(game, found[1])
		_hold(game, c[0])
		var before := game.dropped_items().size()
		assert_gt(_swings_to_clear(game, cell), 0, "%s on %s must harvest" % [c[0], c[1]])
		assert_eq(game.island.deposit_at(cell), Deposit.NONE, "cell must be empty")
		assert_false(game.island.is_blocked(cell), "cell must no longer block")
		assert_eq(game.dropped_items().size(), before + 1, "exactly one drop")
		var here := _drops_at(game, cell)
		assert_eq(here.size(), 1, "drop must lie on the harvested cell")
		if here.size() == 1:
			assert_eq(here[0].item_id(), c[2])
			assert_gt(here[0].count(), 0)
			assert_true(here[0].is_inside_tree(), "drop must be in the world")


func test_bare_hand_is_slower_than_the_right_tool() -> void:
	var game := _enter()
	for pair in [[AXE, Deposit.TREE], [PICKAXE, Deposit.STONE]]:
		var a := _find(game, pair[1])
		_stand(game, a[1])
		_hold(game, pair[0])
		var with_tool := _swings_to_clear(game, a[0])
		var b := _find(game, pair[1], [a[0]])
		_stand(game, b[1])
		_hold(game, null)
		var by_hand := _swings_to_clear(game, b[0])
		assert_gt(with_tool, 0)
		assert_gt(by_hand, with_tool, "bare hand must need more swings on %s" % pair[1])


func test_hand_swing_keeps_cell_until_done() -> void:
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, null)
	assert_true(game.harvester().swing(found[0]))
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE, "one bare-hand swing must not fell a tree")
	assert_gt(game.harvester().progress_at(found[0]), 0)
	assert_eq(game.dropped_items().size(), 0)


# --- 맞지 않는 조합: 아무 일도 없다 ---

func test_mismatched_combinations_do_nothing() -> void:
	var game := _enter()
	var cases := [
		[AXE, Deposit.STONE], [AXE, Deposit.ORE],
		[PICKAXE, Deposit.TREE],
		[null, Deposit.ORE],
		[{"id": "wood", "count": 5}, Deposit.TREE],
		[AXE, Deposit.NONE], [PICKAXE, Deposit.NONE], [null, Deposit.NONE],
	]
	for c in cases:
		var cell: Vector2i
		if c[1] == Deposit.NONE:
			cell = game.island.spawn() + Vector2i(1, 0)
			_stand(game, game.island.spawn())
		else:
			var found := _find(game, c[1])
			cell = found[0]
			_stand(game, found[1])
		_hold(game, c[0])
		for i in 10:
			assert_false(game.harvester().swing(cell), "%s on %s must do nothing" % [c[0], c[1]])
		assert_eq(game.island.deposit_at(cell), c[1], "cell must be unchanged")
		assert_false(game.island.is_removed(cell))
		assert_eq(game.harvester().progress_at(cell), 0)
	assert_eq(game.dropped_items().size(), 0, "nothing may drop")


# --- 손이 닿는 거리 ---

func test_out_of_reach_does_nothing_and_in_reach_works() -> void:
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	var cell: Vector2i = found[0]
	var center := game.island_view().cell_center(cell)
	var reach := _cfg().reach_px(game.island_view().tile_px())
	_hold(game, AXE)
	for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2(-1, -1).normalized()]:
		game.player().global_position = center + dir * (reach + 1.0)
		for i in 5:
			assert_false(game.harvester().swing(cell), "must not reach from %s" % [dir])
	assert_eq(game.island.deposit_at(cell), Deposit.TREE)
	assert_eq(game.dropped_items().size(), 0)
	game.player().global_position = center + Vector2.RIGHT * (reach - 1.0)
	assert_true(game.harvester().swing(cell), "must reach just inside the limit")
	assert_eq(game.island.deposit_at(cell), Deposit.NONE)


# --- 빈 칸은 더 이상 막지 않는다 ---

func test_harvested_cell_no_longer_collides() -> void:
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	await wait_physics_frames(2)
	var query := PhysicsPointQueryParameters2D.new()
	query.position = game.island_view().cell_center(found[0])
	var space := game.get_world_2d().direct_space_state
	assert_gt(space.intersect_point(query).size(), 0, "tree must block before harvest")
	assert_true(game.harvester().swing(found[0]))
	await wait_physics_frames(2)
	assert_eq(space.intersect_point(query).size(), 0, "empty cell must not block")
	await _leave_physics_frame()
