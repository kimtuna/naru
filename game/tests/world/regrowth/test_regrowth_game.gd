extends "res://tests/life/harvest/harvest_test_base.gd"
## G-004 5단계 — 게임 안에서의 재생: 캔 칸이 시간이 지나면 돌아오고, 흐른 시간과 없앤 시각은 저장에 남는다.

const SEED := 9191


func world_seed() -> int:
	return SEED


func _leave(game: GameScene) -> void:
	game.exit_to_menu()
	Screens.last_request = ""
	game.free()
	await wait_process_frames(1)


func _fell_tree(game: GameScene) -> Vector2i:
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	assert_gt(_swings_to_clear(game, found[0]), 0, "setup: harvest failed")
	return found[0]


func test_game_regrows_felled_tree_after_player_walks_away() -> void:
	var game := _enter()
	assert_not_null(game.regrowth().map, "regrowth is wired to the island")
	var tree := _fell_tree(game)
	var period := game.regrowth().config.period_of(Deposit.TREE)
	# 플레이어가 그 칸에 서 있으면 안 자란다.
	_stand(game, tree)
	game.regrowth().advance(period + 1.0)
	game.regrowth().check()
	assert_eq(game.island.deposit_at(tree), Deposit.NONE)
	_stand(game, tree + Vector2i(4, 4))
	game.regrowth().check()
	assert_eq(game.island.deposit_at(tree), Deposit.TREE)
	var chunk := game.island_view().chunk_node(game.island.chunk_of(tree))
	assert_not_null(chunk)
	await _leave_physics_frame()


func test_time_and_removal_times_survive_saving() -> void:
	var game := _enter()
	var cfg := game.regrowth().config
	var period := cfg.period_of(Deposit.TREE)
	game.regrowth().advance(100.0)
	var tree := _fell_tree(game)
	_stand(game, tree + Vector2i(5, 5))
	game.regrowth().advance(period - 10.0)
	assert_eq(game.island.deposit_at(tree), Deposit.NONE)
	var time := game.island.time
	await _leave(game)

	var saved := Session.store.load_world(_world_id)
	assert_almost_eq(saved.world_time, time, 0.001)
	assert_almost_eq(float(saved.removed_at.get(tree, -1.0)), 100.0, 0.001)

	var again := _enter()
	assert_almost_eq(again.island.time, time, 0.001, "world time continues")
	_stand(again, tree + Vector2i(5, 5))
	again.regrowth().check()
	assert_eq(again.island.deposit_at(tree), Deposit.NONE, "not yet — only part of the period passed")
	again.regrowth().advance(20.0)
	again.regrowth().check()
	assert_eq(again.island.deposit_at(tree), Deposit.TREE)
	await _leave(again)
	var last := Session.store.load_world(_world_id)
	assert_false(last.removed_cells.has(tree), "regrown cell leaves the save")
	assert_false(last.removed_at.has(tree))


func test_world_data_round_trip_keeps_times() -> void:
	var w := WorldData.create("W", 5)
	w.removed_cells[Vector2i(3, 4)] = true
	w.removed_at[Vector2i(3, 4)] = 12.5
	w.world_time = 99.0
	var back := WorldData.from_dict(w.to_dict())
	assert_eq(back.removed_at, w.removed_at)
	assert_eq(back.world_time, 99.0)
	var old := WorldData.from_dict({"name": "O", "seed": 1, "removed": [Vector2i(1, 1)]})
	assert_eq(old.world_time, 0.0)
	assert_eq(old.removed_at.size(), 0, "old saves: removal time unknown → counted from 0")
