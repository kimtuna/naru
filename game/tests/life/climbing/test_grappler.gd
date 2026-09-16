extends "res://tests/craft/stations/station_test_base.gd"
## G-014 4단계 — 갈고리총 (게임 안에서). 데이터 · 레시피는 test_grapple_config.gd.
## 좌클릭하면 Pointer 쪽으로 쏘아 걸린 곳(최대 거리 · 겨눈 지점)으로 날아간다. 탄창이 비면 쏘지 않는다.
## 절벽에 닿으면 매달려 기력이 줄고, 줄을 끊으면 아래쪽 걸을 수 있는 칸까지 떨어진다. 드는 동안 채취하지 않는다.

const Cliffs := preload("res://tests/world/island/test_island_cliffs.gd")
const RIGHT := Vector2i(1, 0)
const GUN := "grapple_gun"
const GUN_2 := "grapple_gun_2"
const STRAIGHT := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## 날아가 닿을 때까지 넉넉히 기다리는 물리 프레임.
const FLIGHT_FRAMES := 60


func world_seed() -> int:
	return 20260916


func _cfg_grapple() -> GrappleConfig:
	return GrappleConfig.load_default()


func _gun(id := GUN) -> Dictionary:
	return {"id": id, "count": 1}


func _loaded(game: GameScene) -> int:
	return _cfg_grapple().loaded(_held(game))


## 실제 좌클릭 한 번 — Pointer 를 at 에 두고 누르고 뗀다.
func _left_click_at(at: Vector2) -> void:
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(at)
	_click(true, screen_mid)
	await wait_physics_frames(2)
	_click(false, screen_mid)
	await wait_physics_frames(1)


## d 쪽으로 length 칸이 모두 걸을 수 있는(절벽 · 막힘 없는) 줄의 시작 칸. 스폰에서 가까운 순.
func _open_line(map: IslandMap, length: int) -> Array:
	var s := map.spawn()
	for r in range(0, 80):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				for d: Vector2i in STRAIGHT:
					var c := s + Vector2i(dx, dy)
					var ok := true
					for k in length + 1:
						if not map.has_cell(c + d * k) or map.is_blocked(c + d * k):
							ok = false
							break
					if ok:
						return [c, d]
	fail_test("no open line of %d cells near spawn" % length)
	return [s, RIGHT]


## 오른쪽이 절벽인 걸을 수 있는 칸에 선다 — 그 절벽 칸.
func _stand_left_of_cliff(game: GameScene) -> Vector2i:
	var cliff := Cliffs.approach(game.island, RIGHT, true)
	assert_ne(cliff, Vector2i(-1, -1), "setup: no cliff near spawn")
	_stand(game, cliff - RIGHT)
	assert_false(game.island.is_cliff(cliff - RIGHT), "setup: standing off the cliff")
	return cliff


## 갈고리총으로 오른쪽 절벽 칸에 매달린다 (스파이크 없이).
func _hang_on_cliff(game: GameScene) -> Vector2i:
	var cliff := _stand_left_of_cliff(game)
	_hold(game, _gun())
	assert_false(game.player().can_climb(), "setup: no spikes")
	await _left_click_at(game.island_view().cell_center(cliff))
	await wait_physics_frames(FLIGHT_FRAMES)
	assert_true(game.grappler().is_hanging(), "arriving on a cliff hangs")
	return cliff


# --- 쏘기 · 날아가기 ---

func test_aiming_beyond_max_range_lands_at_max_range() -> void:
	_hide_gut_layer()
	for id in [GUN, GUN_2]:
		var game := _enter()
		var view := game.island_view()
		var tiles := int(_cfg_grapple().stat(_gun(id), "range_tiles"))
		var line := _open_line(game.island, tiles)
		var start: Vector2i = line[0]
		var d: Vector2i = line[1]
		_stand(game, start)
		_hold(game, _gun(id))
		var from := game.player().global_position
		await _left_click_at(view.cell_center(start + d * (tiles + 6)))
		var expected := from + Vector2(d) * tiles * view.tile_px()
		assert_almost_eq(game.grappler().hook, expected, Vector2(0.01, 0.01), id + " hooks at its max range")
		await wait_physics_frames(FLIGHT_FRAMES)
		assert_almost_eq(game.player().global_position, expected, Vector2(0.01, 0.01), id + " flies to the hook")
		assert_false(game.grappler().is_hanging(), "ground does not hang")
		assert_false(game.player().flying)
		assert_eq(game.swinger().swing_count, 0, "firing is not a swing")
		game.free()
		_games.clear()
	await _leave_physics_frame()


func test_aiming_short_lands_where_aimed_and_uses_one_shot() -> void:
	_hide_gut_layer()
	var game := _enter()
	var view := game.island_view()
	var line := _open_line(game.island, 3)
	var start: Vector2i = line[0]
	var d: Vector2i = line[1]
	_stand(game, start)
	_hold(game, _gun(GUN_2))
	var mag := _cfg_grapple().magazine(_gun(GUN_2))
	assert_eq(_loaded(game), mag, "a new grapple gun is full")
	var aim := view.cell_center(start + d * 2) + Vector2(d.y, d.x) * 3.0
	var shots := [0]
	game.grappler().fired.connect(func(_h: Vector2) -> void: shots[0] += 1)
	await _left_click_at(aim)
	assert_eq(shots[0], 1)
	assert_eq(game.grappler().hook, aim, "short aim hooks at the aimed point")
	assert_true(game.grappler().is_flying(), "flies instead of teleporting")
	assert_eq(_loaded(game), mag - 1, "one shot used from the magazine")
	await wait_physics_frames(FLIGHT_FRAMES)
	assert_almost_eq(game.player().global_position, aim, Vector2(0.01, 0.01), "lands at the aimed point")
	assert_eq(_loaded(game), mag, "standing on ground reloads the held grapple gun")
	await _leave_physics_frame()


func test_flight_stops_before_a_blocked_cell() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	var tree: Vector2i = found[0]
	_stand(game, found[1])
	_hold(game, _gun(GUN_2))
	await _left_click_at(game.island_view().cell_center(tree))
	await wait_physics_frames(FLIGHT_FRAMES)
	var at := game.island_view().world_to_cell(game.player().global_position)
	assert_false(game.island.is_solid(at), "does not end inside the tree")
	assert_eq(at, found[1], "stops in front of the tree")
	await _leave_physics_frame()


# --- 탄창 ---

func test_empty_magazine_does_not_fire() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := await _hang_on_cliff(game)
	var here := game.island_view().cell_center(cliff)
	var shots := [0, 0]
	game.grappler().fired.connect(func(_h: Vector2) -> void: shots[0] += 1)
	game.grappler().dry_fired.connect(func() -> void: shots[1] += 1)
	var mag := _cfg_grapple().magazine(_gun())
	assert_eq(_loaded(game), mag - 1, "hanging on a cliff does not reload")
	for i in mag - 1:
		await _left_click_at(here)
		await wait_physics_frames(10)
	assert_eq(shots[0], mag - 1, "fires until the magazine is empty")
	assert_eq(_loaded(game), 0)
	var before := game.player().global_position
	await _left_click_at(game.island_view().cell_center(cliff - RIGHT))
	await wait_physics_frames(FLIGHT_FRAMES)
	assert_eq(shots[0], mag - 1, "an empty magazine does not fire")
	assert_eq(shots[1], 1, "a dry fire is reported")
	assert_eq(game.player().global_position, before, "does not move")
	assert_true(game.grappler().is_hanging(), "still hanging")
	assert_eq(game.swinger().swing_count, 0, "an empty grapple gun does not swing either")
	await _leave_physics_frame()


# --- 매달리기 · 줄 끊기 ---

func test_arriving_on_a_cliff_hangs_and_drains_stamina() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := await _hang_on_cliff(game)
	var p := game.player()
	var here := game.island_view().cell_center(cliff)
	assert_eq(p.global_position, here, "hangs at the hooked cliff")
	assert_true(p.hanging)
	assert_false(game.climber().is_falling(), "no spikes but does not fall while hanging")
	assert_true(game.climber().shows_stamina(), "stamina bar is shown")
	var stamina := game.climber().stamina
	var before := stamina.current
	Input.action_press(InputActions.MOVE_LEFT)
	await wait_physics_frames(30)
	Input.action_release(InputActions.MOVE_LEFT)
	assert_eq(p.global_position, here, "hanging on the rope does not walk")
	var expected := before - stamina.config.hang_drain_per_second * 30.0 / Engine.physics_ticks_per_second
	assert_lt(stamina.current, before, "stamina drains while hanging")
	assert_almost_eq(stamina.current, expected, 1.0)
	await _leave_physics_frame()


func test_hanging_until_stamina_runs_out_falls() -> void:
	_hide_gut_layer()
	var game := _enter()
	await _hang_on_cliff(game)
	var stamina := game.climber().stamina
	var falls := [0]
	game.climber().fell.connect(func() -> void: falls[0] += 1)
	stamina.current = 0.0
	stamina.overdraw = stamina.config.grace - 0.01
	await wait_physics_frames(3)
	assert_eq(falls[0], 1, "falls when stamina runs out while hanging")
	assert_false(game.grappler().is_hanging())
	assert_false(game.player().hanging)
	await _leave_physics_frame()


func test_cutting_the_rope_falls_to_a_walkable_cell_below() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := await _hang_on_cliff(game)
	var climber := game.climber()
	var land := climber.landing_cell(cliff)
	var expected := game.player().spawn_point if land == Climber.NO_CELL \
		else game.island_view().cell_center(land)
	var cuts := [0]
	game.grappler().rope_cut.connect(func() -> void: cuts[0] += 1)
	_press_action(InputActions.CUT_ROPE)
	await wait_physics_frames(1)
	assert_eq(cuts[0], 1, "the cut_rope action cuts the rope")
	assert_false(game.grappler().is_hanging())
	assert_false(game.player().hanging)
	await wait_physics_frames(120)
	assert_false(climber.is_falling(), "has landed")
	assert_eq(game.player().global_position, expected, "falls to the walkable cell below")
	if land != Climber.NO_CELL:
		assert_gt(land.y, cliff.y, "the landing cell is below")
		assert_false(game.island.is_blocked(land), "the landing cell is walkable")
	assert_eq(_loaded(game), _cfg_grapple().magazine(_gun()), "reloads back on the ground")
	_press_action(InputActions.CUT_ROPE)
	await wait_physics_frames(1)
	assert_eq(cuts[0], 1, "nothing to cut on the ground")
	await _leave_physics_frame()


# --- 손 ---

func test_holding_the_grapple_gun_does_not_harvest() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	var tree: Vector2i = found[0]
	var aim := game.island_view().cell_center(tree)
	_stand(game, found[1])
	_hold(game, _gun())
	await _left_click_at(aim)
	await wait_physics_frames(FLIGHT_FRAMES)
	assert_eq(game.harvester().progress_at(tree), 0, "the hand holds the grapple gun — no harvest")
	assert_eq(game.swinger().swing_count, 0, "no swing")
	_stand(game, found[1])
	_hold(game, null)
	await _left_click_at(aim)
	assert_eq(game.swinger().swing_count, 1, "setup check: a bare hand swings")
	assert_gt(game.harvester().progress_at(tree), 0, "setup check: a bare hand harvests the same tree")
	await _leave_physics_frame()
