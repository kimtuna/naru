extends "res://tests/life/farming/crop_test_base.gd"
## G-007 2단계 — 심기 · 물 주기 · 성장 · 수확.
## 맨땅 → 개간 → 씨앗(들고 우클릭) → 물 → 성장 → 수확 순서를 건너뛸 수 없고, 물을 안 준 작물은 자라지 않는다.
## 다 자란 작물을 수확하면 작물이 바닥에 떨어진다.


# --- 한 바퀴 ---

func test_full_cycle_with_right_clicks() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	var days := _farm_cfg().grow_days
	assert_eq(days, 3, "wheat grows in 3 days (spec)")
	_hold(game, SHOVEL)
	await _right_click_cell(game, cell)
	assert_true(game.farm().is_tilled(cell))
	_hold(game, _seeds(2))
	await _right_click_cell(game, cell)
	assert_not_null(game.farm().crop_at(cell), "right click with seeds plants on a field")
	assert_eq(_held(game), _seeds(1), "one seed is used")
	_hold(game, _can())
	for day in days:
		assert_false(game.farm().is_ripe(cell), "not ripe before day %d" % day)
		await _right_click_cell(game, cell)
		assert_true(game.farm().crop_at(cell).watered, "right click with the watering can waters (day %d)" % day)
		_next_day(game)
		assert_eq(game.farm().crop_at(cell).days, day + 1)
	assert_true(game.farm().is_ripe(cell), "ripe after %d watered days" % days)
	assert_eq(_held(game), _can(), "the watering can is not used up")
	assert_eq(_wheat_drops(game, cell).size(), 0)
	await _right_click_cell(game, cell)
	assert_null(game.farm().crop_at(cell), "harvested")
	var drops := _wheat_drops(game, cell)
	assert_eq(drops.size(), 1, "the crop drops on the ground")
	assert_eq(drops[0].count(), _farm_cfg().harvest_count)
	assert_true(game.farm().is_tilled(cell), "the field stays after harvest")
	assert_eq(game.swinger().swing_count, 0, "farming is not a swing")
	await _leave_physics_frame()


# --- 순서를 건너뛸 수 없다 ---

func test_seeds_need_a_field() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, _seeds(2))
	await _right_click_cell(game, cell)
	assert_null(game.farm().crop_at(cell), "seeds are not planted on bare ground")
	assert_false(game.farm().is_tilled(cell), "seeds do not till")
	assert_eq(_held(game), _seeds(2), "no seed is used")
	var tree := _find(game, Deposit.TREE)
	_stand(game, tree[1])
	assert_false(game.farm().plant(tree[0]), "not on a resource cell")
	assert_null(game.farm().crop_at(tree[0]))
	await _leave_physics_frame()


func test_water_needs_a_planted_crop() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	_hold(game, _can())
	await _right_click_cell(game, cell)
	assert_false(game.farm().is_tilled(cell), "watering bare ground does nothing")
	assert_true(game.farm().dig(cell))
	await _right_click_cell(game, cell)
	assert_null(game.farm().crop_at(cell), "watering an empty field plants nothing")
	for i in 5:
		_next_day(game)
	_hold(game, _seeds())
	assert_true(game.farm().plant(cell))
	assert_eq(game.farm().crop_at(cell).days, 0, "days before planting do not count")
	assert_false(game.farm().crop_at(cell).watered, "water given before planting does not count")
	await _leave_physics_frame()


func test_only_seeds_plant_and_only_the_can_waters() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _bare_next_to_spawn(game)
	assert_true(game.farm().dig(cell))
	for item in [null, AXE, {"id": "wood", "count": 3}, _can()]:
		_hold(game, item)
		await _right_click_cell(game, cell)
		assert_null(game.farm().crop_at(cell), "%s does not plant" % str(item))
	_hold(game, _seeds())
	await _right_click_cell(game, cell)
	for item in [null, AXE, _seeds()]:
		_hold(game, item)
		await _right_click_cell(game, cell)
		assert_false(game.farm().crop_at(cell).watered, "%s does not water" % str(item))
	await _leave_physics_frame()


func test_cannot_plant_twice_on_one_field() -> void:
	var game := _enter()
	var cell := _planted(game)
	var before := game.farm().crop_at(cell)
	_hold(game, _seeds(3))
	assert_false(game.farm().plant(cell))
	assert_eq(_held(game), _seeds(3), "no seed is used")
	assert_same(game.farm().crop_at(cell), before)
	await _leave_physics_frame()


func test_unripe_crop_cannot_be_harvested() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cell := _planted(game)
	_hold(game, _can())
	for day in _farm_cfg().grow_days - 1:
		assert_true(game.farm().water(cell))
		_next_day(game)
	_hold(game, null)
	await _right_click_cell(game, cell)
	assert_not_null(game.farm().crop_at(cell), "a growing crop is not harvested")
	assert_false(game.farm().harvest(cell))
	assert_eq(_wheat_drops(game, cell).size(), 0, "nothing drops")
	await _leave_physics_frame()


func test_out_of_reach_does_nothing() -> void:
	var game := _enter()
	var cell := _planted(game)
	var here := game.island.spawn()
	game.farm().till(cell + Vector2i(10, 0))
	_hold(game, _seeds())
	assert_false(game.farm().plant(cell + Vector2i(10, 0)), "cannot plant out of reach")
	_stand(game, here + Vector2i(10, 10))
	_hold(game, _can())
	assert_false(game.farm().water(cell), "cannot water out of reach")
	_stand(game, here)
	for day in _farm_cfg().grow_days:
		assert_true(game.farm().water(cell))
		_next_day(game)
	_stand(game, here + Vector2i(10, 10))
	assert_false(game.farm().harvest(cell), "cannot harvest out of reach")
	assert_true(game.farm().is_ripe(cell))
	await _leave_physics_frame()


# --- 물을 안 주면 자라지 않는다 ---

func test_unwatered_crop_does_not_grow() -> void:
	var game := _enter()
	var cell := _planted(game)
	for i in 10:
		_next_day(game)
	assert_eq(game.farm().crop_at(cell).days, 0, "no water, no growth")
	assert_false(game.farm().is_ripe(cell))
	await _leave_physics_frame()


func test_water_lasts_one_day() -> void:
	var game := _enter()
	var cell := _planted(game)
	_hold(game, _can())
	assert_true(game.farm().water(cell))
	assert_false(game.farm().water(cell), "already watered today")
	game.clock().advance(game.clock().config.day_seconds * 5.0)
	assert_eq(game.farm().crop_at(cell).days, 1, "one watering grows one day, even when days pass at once")
	assert_false(game.farm().crop_at(cell).watered, "the water dries at the day change")
	assert_true(game.farm().water(cell), "can water again the next day")
	await _leave_physics_frame()


func test_growth_waits_for_the_day_change() -> void:
	var game := _enter()
	var cell := _planted(game)
	_hold(game, _can())
	assert_true(game.farm().water(cell))
	game.clock().advance(game.clock().config.day_seconds * 0.9)
	assert_eq(game.farm().crop_at(cell).days, 0, "still the same day")
	game.clock().advance(game.clock().config.day_seconds * 0.2)
	assert_eq(game.farm().crop_at(cell).days, 1)
	await _leave_physics_frame()


func test_ripe_crop_does_not_take_water() -> void:
	var game := _enter()
	var cell := _planted(game)
	_hold(game, _can())
	for day in _farm_cfg().grow_days + 2:
		game.farm().water(cell)
		_next_day(game)
	assert_eq(game.farm().crop_at(cell).days, _farm_cfg().grow_days, "stops growing when ripe")
	assert_false(game.farm().water(cell))
	await _leave_physics_frame()


# --- 되돌리기 ---

func test_shovel_on_a_planted_field_gives_the_seed_back() -> void:
	var game := _enter()
	var cell := _planted(game)
	_hold(game, SHOVEL)
	assert_true(game.farm().dig(cell))
	assert_false(game.farm().is_tilled(cell))
	assert_null(game.farm().crop_at(cell))
	var seeds := _drops_at(game, cell).filter(func(d: DroppedItem) -> bool: return d.item_id() == _farm_cfg().seed_id)
	assert_eq(seeds.size(), 1, "the seed drops back")
	assert_eq(_wheat_drops(game, cell).size(), 0)
	await _leave_physics_frame()
