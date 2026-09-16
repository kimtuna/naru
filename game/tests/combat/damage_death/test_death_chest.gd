extends "res://tests/combat/damage_death/death_chest_test_base.gd"
## G-009 3단계 — 데스 상자 (spec/08_combat/damage-death.md).
## 페널티 켬: 죽은 자리에 상자 · 가방 전부가 옮겨짐 · 여러 번 죽으면 여러 개 · 페널티 끔: 그대로.
## 30분 뒤 사라짐 · 창이 열린 동안 멈춤 · 본인만 연다.


# --- 수치는 한 곳 ---

func test_chest_timer_is_thirty_minutes_in_config() -> void:
	assert_eq(_chest_seconds(), 30.0 * 60.0)
	for path in ["res://combat/damage_death/death_chest.gd", "res://combat/damage_death/death_chests.gd"]:
		assert_false(FileAccess.get_file_as_string(path).contains("1800"), path + " hard-codes the timer")


# --- 페널티 켬 ---

func test_penalty_on_drops_chest_with_whole_bag_at_death_spot() -> void:
	var game := _enter()
	assert_true(game.death_penalty_on(), "penalty is on by default")
	var inv := _fill_bag(game)
	var at := _die_at(game, Vector2(64, -32))
	assert_true(_bag_is_empty(inv), "bag (hotbar included) is emptied")
	assert_null(game.player().held_item(), "hands are empty after respawn")
	var chests := game.death_chests().all()
	assert_eq(chests.size(), 1)
	var chest := chests[0]
	assert_eq(chest.position, at, "chest lies where the character died")
	assert_eq(chest.owner_id, game.character.id)
	assert_eq(chest.count_of("axe"), 1, "hotbar item is in the chest")
	assert_eq(chest.count_of("stone"), 3, "back-of-bag item is in the chest")
	assert_eq(chest.count_of("wood"), 7)
	assert_eq(chest.time_left, _chest_seconds())
	assert_true(chest.is_inside_tree() and chest.get_parent() == game.death_chests())


func test_dying_twice_leaves_two_chests() -> void:
	var game := _enter()
	var inv := _fill_bag(game)
	var first := _die_at(game, Vector2(64, 0))
	inv.add({"id": "wheat", "count": 2})
	var second := _die_at(game, Vector2(0, 64))
	var chests := game.death_chests().all()
	assert_eq(chests.size(), 2, "one chest per death")
	assert_eq(chests[0].position, first)
	assert_eq(chests[0].count_of("wood"), 7)
	assert_eq(chests[1].position, second)
	assert_eq(chests[1].count_of("wheat"), 2)
	assert_eq(chests[1].count_of("wood"), 0, "first chest's items are not duplicated")
	assert_true(_bag_is_empty(inv))


func test_penalty_off_keeps_bag_and_drops_nothing() -> void:
	var game := _enter()
	_set_penalty(game, false)
	var inv := _fill_bag(game)
	_die_at(game, Vector2(64, 0))
	assert_eq(game.death_chests().all().size(), 0, "no chest")
	assert_eq(inv.count_of("axe"), 1)
	assert_eq(inv.count_of("stone"), 3)
	assert_eq(inv.count_of("wood"), 7)
	assert_eq(game.player().held_item(), AXE, "still holding the axe")


func test_switching_penalty_mid_game_applies_to_next_death() -> void:
	var game := _enter()
	var inv := _fill_bag(game)
	_set_penalty(game, false)
	_die_at(game, Vector2(64, 0))
	assert_eq(game.death_chests().all().size(), 0)
	_set_penalty(game, true)
	_die_at(game, Vector2(64, 0))
	assert_eq(game.death_chests().all().size(), 1)
	assert_true(_bag_is_empty(inv))


# --- 30분 타이머 ---

func test_chest_and_items_vanish_after_thirty_minutes() -> void:
	var game := _enter()
	_fill_bag(game)
	_die_at(game, Vector2(64, 0))
	var chest := game.death_chests().all()[0]
	watch_signals(chest)
	game.death_chests().advance(_chest_seconds() - 1.0)
	assert_false(chest.is_gone(), "still there one second before")
	assert_almost_eq(chest.time_left, 1.0, 0.001)
	game.death_chests().advance(1.0)
	assert_true(chest.is_gone())
	assert_signal_emitted(chest, "expired")
	assert_eq(chest.items.size(), 0, "items vanish with the chest")
	assert_eq(game.death_chests().all().size(), 0)
	assert_eq(game.death_chests().to_list(), [], "nothing left to save")
	await wait_process_frames(1)
	assert_false(is_instance_valid(chest), "chest node is removed")
	assert_eq(game.player().hotbar.inventory.count_of("wood"), 0, "items did not come back")


func test_time_runs_by_frames_and_can_be_sped_up() -> void:
	var game := _enter()
	_fill_bag(game)
	_die_at(game, Vector2(64, 0))
	var chest := game.death_chests().all()[0]
	await wait_process_frames(3)
	assert_lt(chest.time_left, _chest_seconds(), "time passes while the world runs")
	game.death_chests().time_scale = _chest_seconds() * 1000.0
	await wait_process_frames(2)
	assert_false(is_instance_valid(chest) and not chest.is_gone(), "fast time makes it vanish")
	assert_eq(game.death_chests().all().size(), 0)


func test_open_window_pauses_timer_and_closing_resumes() -> void:
	var game := _enter()
	_fill_bag(game)
	_die_at(game, Vector2(64, 0))
	var chest := game.death_chests().all()[0]
	_stand_by(game, chest)
	assert_true(game.death_chests().open(chest, game.character.id))
	assert_true(game.death_chest_view().is_open())
	assert_true(chest.is_paused())
	var left := chest.time_left
	game.death_chests().advance(_chest_seconds() * 2.0)
	assert_eq(chest.time_left, left, "no time passes while open")
	assert_false(chest.is_gone())
	game.death_chests().time_scale = 100.0
	await wait_process_frames(3)
	assert_eq(chest.time_left, left, "frames do not tick it while open either")
	game.death_chests().time_scale = 1.0
	game.on_escape()
	assert_false(game.death_chest_view().is_open(), "Esc closes the window")
	assert_false(chest.is_paused())
	game.death_chests().advance(10.0)
	assert_almost_eq(chest.time_left, left - 10.0, 0.001, "time runs again after closing")


# --- 본인만 ---

func test_owner_opens_and_takes_everything() -> void:
	var game := _enter()
	var inv := _fill_bag(game)
	_die_at(game, Vector2(64, 0))
	var chest := game.death_chests().all()[0]
	_stand_by(game, chest)
	var cell := game.island_view().world_to_cell(chest.position)
	assert_true(game.interactor().interact(cell), "right-click on own chest opens it")
	var view := game.death_chest_view()
	assert_true(view.is_open())
	assert_eq(view.chest, chest)
	assert_true(view.slot_has_item(0))
	assert_true(game.ui_blocks_click(), "open window blocks swinging")
	watch_signals(chest)
	view.take_all_button().pressed.emit()
	assert_eq(inv.count_of("axe"), 1)
	assert_eq(inv.count_of("stone"), 3)
	assert_eq(inv.count_of("wood"), 7)
	assert_signal_emitted(chest, "emptied")
	assert_true(chest.is_gone(), "empty chest disappears")
	assert_false(view.is_open(), "window closes with the chest")
	assert_eq(game.death_chests().all().size(), 0)


func test_other_player_is_refused() -> void:
	var game := _enter()
	_fill_bag(game)
	_die_at(game, Vector2(64, 0))
	var chest := game.death_chests().all()[0]
	_stand_by(game, chest)
	var other := CharacterData.new()
	assert_ne(other.id, game.character.id, "characters get different ids")
	var other_bag := Inventory.new(other)
	watch_signals(game.death_chests())
	assert_false(game.death_chests().open(chest, other.id), "someone else cannot open it")
	assert_signal_emitted(game.death_chests(), "refused")
	assert_false(game.death_chest_view().is_open())
	assert_false(chest.is_paused(), "a refused open does not stop the timer")
	assert_eq(chest.take_all(other.id, other_bag), 0, "someone else cannot take items")
	assert_eq(chest.take(0, other.id, other_bag), 0)
	assert_eq(other_bag.count_of("wood") + other_bag.count_of("axe") + other_bag.count_of("stone"), 0)
	assert_eq(chest.count_of("wood"), 7, "items stay in the chest")
	assert_false(chest.is_gone())
	assert_false(game.death_chests().open(chest, ""), "no id, no access")


func test_right_click_on_someone_elses_chest_is_refused() -> void:
	var game := _enter()
	var at := game.player().spawn_point + Vector2(64, 0)
	var chest := game.death_chests().add_chest(DeathChest.create("someone-else", [WOOD], at, 60.0))
	_stand_by(game, chest)
	watch_signals(game.death_chests())
	assert_true(game.interactor().interact(game.island_view().world_to_cell(at)), "click lands on the chest")
	assert_signal_emitted(game.death_chests(), "refused")
	assert_false(game.death_chest_view().is_open())
	assert_eq(game.player().hotbar.inventory.count_of("wood"), 0)


func test_out_of_reach_chest_does_not_open_and_open_window_closes_when_walking_away() -> void:
	var game := _enter()
	_fill_bag(game)
	_die_at(game, Vector2(160, 0))
	var chest := game.death_chests().all()[0]
	var cell := game.island_view().world_to_cell(chest.position)
	assert_false(game.death_chests().try_open(cell), "too far — nothing happens")
	_stand_by(game, chest)
	assert_true(game.death_chests().try_open(cell))
	game.player().global_position = chest.position + Vector2(400, 0)
	await wait_process_frames(2)
	assert_false(game.death_chest_view().is_open(), "walking away closes the window")
	assert_false(chest.is_paused(), "timer runs again")
