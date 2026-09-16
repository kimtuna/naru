extends "res://tests/craft/stations/station_test_base.gd"
## G-006 3단계 — 제작 타이머와 출력 버퍼 (spec/05_craft/crafting-stations.md).

const INGOT := "iron_ingot"
const AMMO := "ammo"


func _bag(game: GameScene) -> Inventory:
	return game.player().hotbar.inventory


## 스폰 옆에 작업대를 두고 철 주괴 재료를 times 번 만들 만큼 가방에 넣는다.
func _ready_bench(game: GameScene, times := 1) -> CraftStation:
	var here := game.island.spawn()
	_stand(game, here)
	var station := game.stations().add_station(WORKBENCH, here + Vector2i.RIGHT)
	var r := RecipeBook.load_default().get_recipe(INGOT)
	for it in r.inputs:
		_bag(game).add({"id": it.id, "count": it.count * times})
	return station


func _recipe(id: String) -> Dictionary:
	return RecipeBook.load_default().get_recipe(id)


func test_result_appears_in_buffer_only_after_timer() -> void:
	var game := _enter()
	var station := _ready_bench(game)
	var r := _recipe(INGOT)
	assert_true(station.start(r, _bag(game)), "materials are there, crafting starts")
	assert_eq(station.buffered(INGOT), 0, "nothing in the buffer right after starting")
	assert_eq(_bag(game).count_of(INGOT), 0, "nothing goes to the bag either")
	assert_true(station.is_busy())
	for it in r.inputs:
		assert_eq(_bag(game).count_of(it.id), 0, it.id + " is used when crafting starts")
	station.tick(r.time - 0.1)
	assert_eq(station.buffered(INGOT), 0, "still nothing just before the timer ends")
	assert_true(station.is_busy())
	station.tick(0.2)
	assert_eq(station.buffered(INGOT), r.output.count, "the result is in the buffer when the timer ends")
	assert_false(station.is_busy())
	assert_eq(_bag(game).count_of(INGOT), 0, "the result waits in the buffer, not in the bag")
	await _leave_physics_frame()


func test_timer_runs_with_game_time() -> void:
	var game := _enter()
	var station := _ready_bench(game)
	assert_true(station.start(_recipe(INGOT), _bag(game)))
	var before := station.time_left()
	await wait_process_frames(5)
	assert_lt(station.time_left(), before, "the timer counts down by itself every frame")
	assert_gt(station.time_left(), 0.0, "a few frames are not enough to finish")
	assert_eq(station.buffered(INGOT), 0)
	await _leave_physics_frame()


func test_cannot_start_without_materials_or_while_busy() -> void:
	var game := _enter()
	var station := _ready_bench(game, 2)
	var r := _recipe(INGOT)
	assert_true(station.start(r, _bag(game)))
	var ore := _bag(game).count_of("iron_ore")
	assert_false(station.start(r, _bag(game)), "one job at a time")
	assert_eq(_bag(game).count_of("iron_ore"), ore, "a refused start uses nothing")
	station.tick(r.time)
	assert_true(station.start(r, _bag(game)), "free again after finishing")
	station.tick(r.time)
	assert_false(station.start(r, _bag(game)), "no materials left")
	assert_false(station.start(_recipe("axe"), _bag(game)), "hand recipes are not made at the workbench")
	assert_eq(station.buffered(INGOT), 2 * r.output.count, "finished results pile up in the buffer")
	await _leave_physics_frame()


func test_buffer_stays_until_collected_then_goes_to_bag() -> void:
	var game := _enter()
	var station := _ready_bench(game)
	var r := _recipe(INGOT)
	station.start(r, _bag(game))
	station.tick(r.time)
	station.tick(100.0)
	await wait_process_frames(3)
	assert_eq(station.buffered(INGOT), r.output.count, "the result stays in the buffer until collected")
	assert_eq(_bag(game).count_of(INGOT), 0)
	assert_eq(station.collect(_bag(game)), r.output.count)
	assert_eq(_bag(game).count_of(INGOT), r.output.count, "collecting moves the result to the bag")
	assert_eq(station.buffered(INGOT), 0)
	assert_true(station.buffer.is_empty())
	await _leave_physics_frame()


func test_full_bag_leaves_the_rest_in_buffer() -> void:
	var game := _enter()
	var station := _ready_bench(game)
	var bag := _bag(game)
	for i in bag.size():
		bag.set_slot(i, {"id": "stone", "count": InventoryConfig.STACK_MAX})
	bag.set_slot(bag.size() - 1, {"id": AMMO, "count": InventoryConfig.STACK_MAX - 4})
	station.add_to_buffer({"id": AMMO, "count": 10})
	station.add_to_buffer({"id": INGOT, "count": 2})
	assert_eq(station.collect(bag), 4, "only the room left in the bag is taken")
	assert_eq(bag.count_of(AMMO), InventoryConfig.STACK_MAX)
	assert_eq(station.buffered(AMMO), 6, "the rest of the ammo stays in the buffer")
	assert_eq(station.buffered(INGOT), 2, "items with no room stay in the buffer")
	assert_eq(bag.count_of(INGOT), 0)
	bag.set_slot(0, null)
	assert_eq(station.collect(bag), 6, "after making room the rest of the ammo is collected")
	assert_eq(station.buffered(AMMO), 0, "ammo went into the freed slot")
	assert_eq(station.buffered(INGOT), 2, "no slot left for the ingots — still waiting")
	await _leave_physics_frame()


func test_progress_and_buffer_survive_saving() -> void:
	var game := _enter()
	var station := _ready_bench(game, 2)
	var cell := station.cell
	var r := _recipe(INGOT)
	station.start(r, _bag(game))
	station.tick(r.time)
	station.start(r, _bag(game))
	station.tick(2.0)
	var left := station.time_left()
	assert_gt(left, 0.0, "setup: the second job is half done")
	game.exit_to_menu()
	Screens.last_request = ""
	game.free()
	await wait_process_frames(1)
	var saved := Session.store.load_world(_world_id)
	assert_eq(saved.stations.size(), 1)
	assert_eq(saved.stations[0].get("buffer"), [{"id": INGOT, "count": r.output.count}])
	assert_eq(saved.stations[0].get("job", {}).get("recipe"), INGOT)
	var again := _enter()
	var back := again.stations().station_at(cell)
	assert_not_null(back)
	if back == null:
		return
	assert_true(back.is_busy(), "the running job is back")
	assert_almost_eq(back.time_left(), left, 0.1, "with the time that was left")
	assert_eq(back.buffered(INGOT), r.output.count, "the buffer is back")
	back.tick(back.time_left())
	assert_eq(back.buffered(INGOT), 2 * r.output.count, "the loaded job finishes into the buffer")
	await _leave_physics_frame()


func test_craft_time_comes_from_each_recipe() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(RecipeBook.DEFAULT_PATH))
	assert_true(data is Dictionary)
	for r in data.recipes:
		assert_true(r.has("time"), r.id + ": every recipe has its own time")
		assert_eq(float(r.time), 5.0, r.id + ": all times are the temporary 5 seconds for now")
		assert_eq(r.get("time_temp"), true, r.id + ": the data says the time is temporary")
	for r in RecipeBook.load_default().recipes:
		assert_true(r.time_temp, r.id + ": the book keeps the temporary mark")
	# 스테이션은 레시피의 time 을 그대로 쓴다 — 레시피마다 다른 값이면 다르게 걸린다.
	var game := _enter()
	var station := _ready_bench(game)
	var quick := _recipe(INGOT).duplicate(true)
	quick.time = 1.5
	assert_true(station.start(quick, _bag(game)))
	assert_almost_eq(station.time_left(), 1.5, 0.05)
	station.tick(1.4)
	assert_eq(station.buffered(INGOT), 0)
	station.tick(0.2)
	assert_eq(station.buffered(INGOT), 1)
	await _leave_physics_frame()


func test_crafting_screen_starts_and_collects() -> void:
	_hide_gut_layer()
	var game := _enter()
	var station := _ready_bench(game)
	await _right_click_cell(game, station.cell)
	var view := game.crafting_view()
	assert_true(view.is_open(), "setup: the station is open")
	var button := view.recipe_button(INGOT)
	assert_not_null(button)
	assert_false(button.disabled, "materials are in the bag")
	assert_true(view.recipe_button("gun").disabled, "no materials for a gun")
	button.pressed.emit()
	assert_true(station.is_busy(), "the recipe button starts crafting")
	assert_eq(view.shown_buffer(), [])
	assert_true(button.disabled, "one job at a time")
	assert_eq(view.get_node("%Status").text, tr("CRAFT_PROGRESS") % [tr("ITEM_IRON_INGOT"), 5])
	assert_true(view.get_node("%Collect").disabled, "nothing to collect yet")
	station.tick(station.time_left())
	await wait_process_frames(1)
	assert_eq(view.shown_buffer(), [{"id": INGOT, "count": 1}], "the screen shows the buffer")
	assert_eq(view.get_node("%Status").text, tr("CRAFT_IDLE"))
	var collect: Button = view.get_node("%Collect")
	assert_false(collect.disabled)
	collect.pressed.emit()
	assert_eq(_bag(game).count_of(INGOT), 1, "the collect button moves the buffer to the bag")
	assert_true(station.buffer.is_empty())
	assert_eq(view.shown_buffer(), [])
	assert_true(collect.disabled)
	await _leave_physics_frame()
