extends "res://tests/life/harvest/harvest_test_base.gd"
## G-011 1단계 — 좌클릭 평타: 무엇을 들었든 바라보는 방향으로 휘두르고, 앞의 손 닿는 대상이 맞는다.
## 몹도 같은 경로(Swinger.add_source)로 맞는다. 가방 · 제작 화면이 열려 있으면 휘두르지 않는다.

const MOB := &"mob"


func world_seed() -> int:
	return 777


## 커서를 흉내 내고 실제 좌클릭을 한 번 누르고 뗀다.
func _click_toward(pos: Vector2) -> void:
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(pos)
	_click(true, screen_mid)
	await wait_physics_frames(2)
	_click(false, screen_mid)
	await wait_physics_frames(1)


func _free_spot(game: GameScene) -> Vector2i:
	# 둘레 손 닿는 범위에 자원이 없는 칸 — 휘둘러도 맞을 것이 없다.
	var s := game.island.spawn()
	var reach := ceili(_swing_cfg().reach_tiles) + 1
	for r in range(0, 40):
		for y in range(s.y - r, s.y + r + 1):
			for x in range(s.x - r, s.x + r + 1):
				var c := Vector2i(x, y)
				var clear := true
				for dy in range(-reach, reach + 1):
					for dx in range(-reach, reach + 1):
						if game.island.is_blocked(c + Vector2i(dx, dy)):
							clear = false
				if clear:
					return c
	fail_test("no clear spot")
	return s


func test_click_swings_whatever_is_held() -> void:
	_hide_gut_layer()
	var game := _enter()
	var spot := _free_spot(game)
	_stand(game, spot)
	var items := [null, AXE, PICKAXE, {"id": "wood", "count": 3}, {"id": "stone", "count": 1}]
	var dirs := [Vector2.RIGHT, Vector2.UP, Vector2(-1, 1).normalized(), Vector2.LEFT, Vector2.DOWN]
	var seen := []
	game.swinger().swung.connect(func(facing: Vector2, target: SwingTarget) -> void:
		seen.append([facing, target]))
	for i in items.size():
		_hold(game, items[i])
		var before := game.swinger().swing_count
		await _click_toward(game.player().global_position + dirs[i] * 20.0)
		assert_eq(game.swinger().swing_count, before + 1, "holding %s, a click swings once" % [items[i]])
		assert_eq(seen.size(), i + 1)
		if seen.size() == i + 1:
			assert_almost_eq(seen[i][0], dirs[i], Vector2(0.001, 0.001), "swings toward where the player faces")
			assert_null(seen[i][1], "nothing to hit around the spot")
	await _leave_physics_frame()


func test_swing_is_shown_then_hidden() -> void:
	var game := _enter()
	_stand(game, _free_spot(game))
	_hold(game, null)
	assert_false(game.player().is_swing_shown())
	game.swinger().swing()
	assert_true(game.player().is_swing_shown(), "a swing is visible")
	await wait_seconds(_swing_cfg().show_time + 0.1)
	assert_false(game.player().is_swing_shown(), "the swing mark goes away")


func test_holding_click_swings_at_the_configured_interval() -> void:
	_hide_gut_layer()
	var game := _enter()
	_stand(game, _free_spot(game))
	_hold(game, null)
	var interval := _swing_cfg().swing_interval
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.player().global_position + Vector2.RIGHT * 20.0)
	_click(true, screen_mid)
	await wait_seconds(interval * 3.5)
	_click(false, screen_mid)
	var count := game.swinger().swing_count
	assert_between(count, 3, 5, "about one swing per interval (got %d)" % count)
	await wait_seconds(interval * 2.0)
	assert_eq(game.swinger().swing_count, count, "released click stops swinging")
	await _leave_physics_frame()


func test_cursor_need_not_be_on_the_target() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var me := game.player().global_position
	var dir := (game.island_view().cell_center(found[0]) - me).normalized()
	# 커서는 나무보다 훨씬 멀리, 조금 비껴 있다.
	var far := me + dir.rotated(0.3) * 200.0
	assert_ne(game.island_view().world_to_cell(far), found[0], "setup: the cursor is not on the tree")
	await _click_toward(far)
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "the tree in front is hit")
	await _leave_physics_frame()


func test_target_out_of_reach_in_front_is_not_hit() -> void:
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	var tree := game.island_view().cell_center(found[0])
	var reach := _swing_cfg().reach_px(game.island_view().tile_px())
	var from := tree + Vector2.RIGHT * (reach + 2.0)
	game.player().global_position = from
	_hold(game, AXE)
	Pointer.simulate(tree)
	var hit := game.swinger().swing()
	if hit:
		assert_ne(hit.what, found[0], "a tree beyond reach is not hit")
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)


func test_mismatched_tool_is_slow_and_ore_needs_pickaxe_through_swings() -> void:
	var game := _enter()
	var counts := {}
	for c in [[PICKAXE, Deposit.STONE], [AXE, Deposit.STONE], [null, Deposit.STONE]]:
		counts[c[0]] = await _swings_in_front(game, c[0], c[1])
	assert_gt(counts[PICKAXE], 0)
	assert_gt(counts[AXE], counts[PICKAXE], "axe on stone is slower than a pickaxe")
	assert_gt(counts[null], counts[PICKAXE], "bare hand on stone is slower than a pickaxe")
	var ore := _find(game, Deposit.ORE)
	for item in [null, AXE]:
		_stand(game, ore[1])
		_hold(game, item)
		Pointer.simulate(game.island_view().cell_center(ore[0]))
		for i in 6:
			var hit := game.swinger().swing()
			assert_not_null(hit, "the ore is hit")
			if hit:
				assert_eq(hit.what, ore[0])
		assert_eq(game.island.deposit_at(ore[0]), Deposit.ORE, "%s cannot mine ore" % [item])
		assert_eq(game.harvester().progress_at(ore[0]), 0)
	assert_gt(await _swings_in_front(game, PICKAXE, Deposit.ORE), 0, "a pickaxe mines ore")


var _used: Array = []


func before_each() -> void:
	super()
	_used = []


func _swings_in_front(game: GameScene, item: Variant, deposit: Deposit) -> int:
	var found := _find(game, deposit, _used)
	_used.append(found[0])
	_stand(game, found[1])
	_hold(game, item)
	Pointer.simulate(game.island_view().cell_center(found[0]))
	for i in range(1, 20):
		var hit := game.swinger().swing()
		if hit == null or hit.what != found[0]:
			return -1
		if game.island.deposit_at(found[0]) == Deposit.NONE:
			await wait_process_frames(1)
			return i
	return 99


## 몹 흉내 — 대상을 내놓고 맞으면 기록한다 (G-009 의 몹이 같은 길로 들어온다).
class FakeMobs:
	var positions: Array[Vector2] = []
	var hits: Array = []

	func targets_near(origin: Vector2, reach: float) -> Array:
		var out := []
		for i in positions.size():
			if origin.distance_to(positions[i]) <= reach:
				out.append(SwingTarget.create(positions[i], 6.0, _hit.bind(i), [MOB, i]))
		return out

	func _hit(item: Variant, i: int) -> bool:
		hits.append([i, item])
		return true


func test_mobs_are_hit_through_the_same_path() -> void:
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var me := game.player().global_position
	var tree := game.island_view().cell_center(found[0])
	var mobs := FakeMobs.new()
	# 나무보다 가까이, 같은 방향에 몹 하나. 등 뒤에 몹 하나.
	mobs.positions = [me + (tree - me) * 0.4, me - (tree - me)]
	game.swinger().add_source(mobs.targets_near)
	Pointer.simulate(tree)
	var hit := game.swinger().swing()
	assert_not_null(hit)
	if hit:
		assert_eq(hit.what, [MOB, 0], "the nearer mob in front takes the hit")
	assert_eq(mobs.hits, [[0, AXE]], "the mob gets the held item, the one behind is not hit")
	assert_eq(game.harvester().progress_at(found[0]), 0, "the tree behind the mob is not hit")
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)
	mobs.positions = [me - (tree - me)]
	game.swinger().swing()
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "without the mob in front, the tree is hit")
	assert_eq(mobs.hits.size(), 1)


func test_no_swing_while_bag_or_crafting_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var tree := game.island_view().cell_center(found[0])
	var station := game.stations().add_station("workbench", _free_neighbor_cell(game, found[1], found[0]))
	for view in [game.inventory_view(), game.crafting_view()]:
		if view == game.inventory_view():
			view.set_open(true)
		else:
			view.open_station(station, RecipeBook.load_default())
		assert_true(view.is_open(), "setup: %s is open" % view.name)
		var before := game.swinger().swing_count
		await _click_toward(tree)
		assert_eq(game.swinger().swing_count, before, "no swing while %s is open" % view.name)
		assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)
		assert_false(game.player().is_swing_shown())
		if view == game.inventory_view():
			view.set_open(false)
		else:
			view.close()
	await _click_toward(tree)
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "closed screens let the swing through")
	await _leave_physics_frame()


func _free_neighbor_cell(game: GameScene, stand: Vector2i, skip: Vector2i) -> Vector2i:
	for n in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(1, 1), Vector2i(-1, -1)]:
		var c: Vector2i = stand + n
		if c != skip and game.stations().is_free(c):
			return c
	fail_test("no free cell next to the player")
	return stand
