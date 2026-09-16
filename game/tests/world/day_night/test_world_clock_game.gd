extends "res://tests/life/harvest/harvest_test_base.gd"
## G-005 1단계 — 게임 안의 시계: 시각과 날짜가 월드 저장에 남고, 다시 들어가면 이어진다.

const DAY := 1200.0


func _leave(game: GameScene) -> void:
	game.exit_to_menu()
	Screens.last_request = ""
	game.free()
	await wait_process_frames(1)


func test_game_has_clock_on_island_time() -> void:
	var game := _enter()
	assert_eq(game.clock().map, game.island)
	assert_eq(game.clock().day(), 1)
	game.clock().advance(DAY * 2 + 700.0)
	assert_almost_eq(game.island.time, DAY * 2 + 700.0, 0.5)
	assert_eq(game.clock().day(), 3)
	assert_true(game.clock().is_night())
	await _leave_physics_frame()


func test_clock_ticks_in_game_without_regrowth_doubling_it() -> void:
	var game := _enter()
	# 시계를 멈추면 시간이 그대로여야 한다 — 재생이 시간을 더하면 바로 드러난다.
	game.clock().speed = 0.0
	var before := game.island.time
	await wait_process_frames(5)
	assert_eq(game.island.time, before, "only the clock moves time")
	await _leave_physics_frame()


func test_clock_ticks_in_game_with_speed() -> void:
	var game := _enter()
	game.clock().speed = 100.0
	var before := game.island.time
	await wait_process_frames(5)
	var passed := game.island.time - before
	assert_gt(passed, 0.0, "time flows in the game")
	await _leave_physics_frame()


func test_time_and_day_survive_saving() -> void:
	var game := _enter()
	game.clock().advance(DAY * 4 + 650.0)
	var day := game.clock().day()
	var tod := game.clock().time_of_day()
	assert_eq(day, 5)
	await _leave(game)

	var saved := Session.store.load_world(_world_id)
	assert_almost_eq(saved.world_time, DAY * 4 + 650.0, 1.0, "save keeps the clock time")

	var again := _enter()
	assert_eq(again.clock().day(), day, "date continues after reload")
	assert_almost_eq(again.clock().time_of_day(), tod, 1.0, "time of day continues after reload")
	assert_true(again.clock().is_night())
	await _leave(again)
