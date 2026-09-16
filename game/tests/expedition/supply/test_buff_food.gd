extends "res://tests/life/farming/crop_test_base.gd"
## G-008 1단계 — 버프 음식 1종 (spec/09_expedition/common.md · spec/04_life/farming.md).
## 작물로 만드는 레시피(제작대 · 타이머 · 버퍼) · 들고 우클릭하면 먹는다 · 정해진 시간 뒤 풀린다 · 이동 속력에 반영된다.

const FOOD := "bread"


func _food_cfg() -> FoodConfig:
	return FoodConfig.load_default()


func _buff_id() -> String:
	return str(_food_cfg().food(FOOD).get("buff", ""))


func _seconds() -> float:
	return float(_food_cfg().food(FOOD).get("seconds", 0.0))


func _bag(game: GameScene) -> Inventory:
	return game.player().hotbar.inventory


## 오른쪽으로 한 물리 걸음 움직인 속력 (실제 물리 루프).
func _step_speed(p: Player) -> float:
	Input.action_press(InputActions.MOVE_RIGHT)
	await get_tree().physics_frame
	var before := p.global_position
	await get_tree().physics_frame
	var moved := (p.global_position - before).length() * Engine.physics_ticks_per_second
	Input.action_release(InputActions.MOVE_RIGHT)
	return moved


func after_each() -> void:
	Input.action_release(InputActions.MOVE_RIGHT)
	super.after_each()


# --- 수치는 한 곳 ---

func test_food_values_live_in_config() -> void:
	var cfg := _food_cfg()
	assert_not_null(cfg, "missing " + FoodConfig.DEFAULT_PATH)
	assert_true(cfg.is_food(FOOD), "bread is a buff food")
	assert_ne(_buff_id(), "", "bread gives a buff")
	assert_gt(_seconds(), 0.0, "buff lasts a set time")
	assert_ne(cfg.effect(_buff_id(), "move_speed", 1.0), 1.0, "buff changes move speed")
	var src := FileAccess.get_file_as_string("res://expedition/supply/eater.gd") \
		+ FileAccess.get_file_as_string("res://expedition/supply/buffs.gd")
	assert_false(src.contains('"%s"' % FOOD), "food id must not be hard-coded")


# --- 작물로 만드는 레시피 (제작대 · 타이머 · 버퍼) ---

func test_recipe_makes_food_from_crop_at_workbench() -> void:
	var book := RecipeBook.load_default()
	var r := book.recipe_for(FOOD)
	assert_false(r.is_empty(), "no recipe makes bread")
	assert_eq(r.station, WORKBENCH, "made at a crafting station, not by hand")
	var crop := _farm_cfg().crop_id
	assert_true(r.inputs.any(func(it): return it.id == crop), "bread is made from the farm crop")
	assert_true(book.is_raw(crop), "crop is a raw material")
	assert_between(book.depth_of(FOOD), 1, RecipeBook.MAX_DEPTH)


func test_food_is_crafted_through_timer_and_buffer() -> void:
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	var station := game.stations().add_station(WORKBENCH, here + Vector2i.RIGHT)
	var r := RecipeBook.load_default().recipe_for(FOOD)
	# 밭에서 수확한 작물을 가방에 넣는다.
	for it in r.inputs:
		_bag(game).add({"id": it.id, "count": it.count})
	assert_true(station.start(r, _bag(game)), "crop in the bag starts crafting")
	assert_eq(station.buffered(FOOD), 0, "not ready right after starting")
	station.tick(r.time - 0.1)
	assert_eq(station.buffered(FOOD), 0, "not ready before the timer ends")
	station.tick(0.2)
	assert_eq(station.buffered(FOOD), r.output.count, "food appears in the output buffer")
	assert_eq(_bag(game).count_of(FOOD), 0, "stays in the buffer until collected")
	assert_eq(station.collect(_bag(game)), r.output.count)
	assert_eq(_bag(game).count_of(FOOD), r.output.count, "collected into the bag")


func test_harvested_wheat_becomes_bread() -> void:
	var game := _enter()
	var cell := _planted(game)
	_hold(game, _can())
	for d in _farm_cfg().grow_days:
		assert_true(game.farm().water(cell))
		_next_day(game)
	assert_true(game.farm().harvest(cell), "setup: ripe wheat is harvested")
	var drops := _wheat_drops(game, cell)
	assert_gt(drops.size(), 0, "harvest drops wheat")
	var r := RecipeBook.load_default().recipe_for(FOOD)
	var wheat := 0
	for d in drops:
		wheat += d.count()
	# 한 번 수확으로 모자라면 같은 작물을 더 거둔 셈으로 채운다.
	var need: int = r.inputs[0].count
	_bag(game).add({"id": drops[0].item_id(), "count": maxi(need, wheat)})
	var station := game.stations().add_station(WORKBENCH, cell + Vector2i.DOWN)
	assert_true(station.start(r, _bag(game)), "wheat from the farm is a bread ingredient")
	await _leave_physics_frame()


# --- 들고 우클릭하면 먹는다 ---

func test_right_click_with_food_eats_one_and_applies_buff() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, {"id": FOOD, "count": 2})
	var p := game.player()
	assert_false(p.buffs.has(_buff_id()), "no buff before eating")
	await _right_click_cell(game, here + Vector2i.LEFT)
	assert_true(p.buffs.has(_buff_id()), "right click with bread applies the buff")
	assert_eq(_held(game), {"id": FOOD, "count": 1}, "one bread is eaten")
	assert_almost_eq(p.buffs.time_left(_buff_id()), _seconds(), 0.5, "buff lasts the configured time")
	await _right_click_cell(game, here + Vector2i.LEFT)
	assert_null(_held(game), "last bread is eaten and the hand is empty")
	assert_almost_eq(p.buffs.time_left(_buff_id()), _seconds(), 0.5, "eating again refreshes, not stacks")


func test_right_click_without_food_gives_no_buff() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, {"id": "wood", "count": 3})
	await _right_click_cell(game, here + Vector2i.LEFT)
	assert_true(game.player().buffs.active().is_empty(), "non-food gives no buff")
	assert_eq(_held(game), {"id": "wood", "count": 3}, "non-food is not eaten")
	_hold(game, null)
	assert_false(game.eater().eat(), "bare hand eats nothing")


func test_eating_is_blocked_while_bag_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, {"id": FOOD, "count": 1})
	game.inventory_view().set_open(true)
	await _right_click_cell(game, here + Vector2i.LEFT)
	assert_false(game.player().buffs.has(_buff_id()), "no eating through the open bag")
	assert_eq(_held(game), {"id": FOOD, "count": 1})


# --- 시간이 지나면 풀린다 ---

func test_buff_expires_after_its_time() -> void:
	var b := Buffs.new()
	var id := _buff_id()
	b.apply(id, _seconds())
	watch_signals(b)
	b.tick(_seconds() - 0.1)
	assert_true(b.has(id), "still active just before the time")
	assert_signal_not_emitted(b, "expired")
	b.tick(0.2)
	assert_false(b.has(id), "gone after the time")
	assert_signal_emitted_with_parameters(b, "expired", [id])
	assert_eq(b.move_speed_multiplier(), 1.0, "no effect after it is gone")


func test_buff_runs_out_in_the_game_loop() -> void:
	var game := _enter()
	var p := game.player()
	p.buffs.apply(_buff_id(), 0.2)
	assert_true(p.buffs.has(_buff_id()))
	await wait_seconds(0.5)
	assert_false(p.buffs.has(_buff_id()), "buff wears off as the game runs")


# --- 버프 효과가 실제 이동 속력에 반영된다 ---

func test_buff_changes_actual_move_speed() -> void:
	var game := _enter()
	var p := game.player()
	_stand(game, game.island.spawn())
	var base := p.tuning.move_speed
	var mult := _food_cfg().effect(_buff_id(), "move_speed", 1.0)
	var plain: float = await _step_speed(p)
	assert_almost_eq(plain, base, 0.01, "base speed without buff")
	_hold(game, {"id": FOOD, "count": 1})
	assert_true(game.eater().eat())
	_stand(game, game.island.spawn())
	var buffed: float = await _step_speed(p)
	assert_almost_eq(buffed, base * mult, 0.01, "buffed speed = base × buff multiplier")
	assert_gt(buffed, plain, "bread makes you faster")
	p.buffs.tick(_seconds() + 1.0)
	_stand(game, game.island.spawn())
	var after: float = await _step_speed(p)
	assert_almost_eq(after, base, 0.01, "speed returns to base when the buff ends")
	await _leave_physics_frame()
