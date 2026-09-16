extends GutTest
## G-014 2단계 — 게임 안에서: 스파이크로 절벽에 들어가 움직이고, 기력 표시가 줄고 차오르며 색이 바뀌고,
## 여유까지 다 쓰면 아래쪽 걸을 수 있는 칸까지 떨어져 낙하 피해를 받는다.

const GAME := "res://world/game.tscn"
const SEED := 20260916
const Cliffs := preload("res://tests/world/island/test_island_cliffs.gd")
const RIGHT := InputActions.MOVE_RIGHT
const DIRS := {
	InputActions.MOVE_RIGHT: Vector2i(1, 0), InputActions.MOVE_LEFT: Vector2i(-1, 0),
	InputActions.MOVE_DOWN: Vector2i(0, 1), InputActions.MOVE_UP: Vector2i(0, -1),
}

var _root := ""


func after_each() -> void:
	for action in DIRS:
		Input.action_release(action)
	Session.store = SaveStore.new()
	Session.clear()
	if _root != "":
		_remove_dir(_root)
		_root = ""


func _enter(spikes: bool) -> GameScene:
	_root = OS.get_temp_dir().path_join("naru_test_climb_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	var ch := CharacterData.new()
	ch.name = "tester"
	if spikes:
		ch.equipment[EquipmentConfig.FEET] = {"id": EquipmentConfig.SPIKES, "count": 1}
	assert_eq(Session.store.save_character(0, ch), OK)
	Session.select_character(0)
	Session.select_world(Session.store.create_world(WorldData.create("island", SEED)))
	var game: GameScene = add_child_autofree((load(GAME) as PackedScene).instantiate())
	assert_eq(game.player().can_climb(), spikes)
	return game


func _teleport(game: GameScene, cell: Vector2i) -> void:
	var p := game.player()
	p.global_position = game.island_view().cell_center(cell)
	p.velocity = Vector2.ZERO
	game.island_view().update_around(p.global_position)
	await wait_physics_frames(2)


## 절벽 칸이 d 쪽으로 len 칸 이어지고 (자원 없이), 그 앞 칸은 걸을 수 있는 곳. 스폰에서 가까운 순.
func _cliff_run(map: IslandMap, d: Vector2i, length: int) -> Vector2i:
	var s := map.spawn()
	for r in range(4, 120):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := s + Vector2i(dx, dy)
				if not map.has_cell(c - d) or map.is_blocked(c - d):
					continue
				var ok := true
				for k in length:
					var e := c + d * k
					var side_a := e + Vector2i(d.y, d.x)
					var side_b := e - Vector2i(d.y, d.x)
					if not map.has_cell(e) or not map.is_cliff(e) or map.is_solid(e) \
							or map.is_solid(side_a) or map.is_solid(side_b):
						ok = false
						break
				if ok:
					return c
	return Vector2i(-1, -1)


func test_without_spikes_cliff_blocks_and_with_spikes_it_is_entered() -> void:
	for spikes in [false, true]:
		var game := _enter(spikes)
		var view := game.island_view()
		for action in DIRS:
			var d: Vector2i = DIRS[action]
			var target := Cliffs.approach(game.island, d, true)
			assert_ne(target, Vector2i(-1, -1))
			await _teleport(game, target - d * 2)
			Input.action_press(action)
			await wait_physics_frames(45)
			Input.action_release(action)
			await wait_physics_frames(1)
			var cell := view.world_to_cell(game.player().global_position)
			var label := "spikes=%s %s" % [spikes, action]
			if spikes:
				assert_true(game.island.is_cliff(cell) or Vector2(cell - target).dot(Vector2(d)) > 0, "%s: got onto the cliff" % label)
			else:
				assert_ne(cell, target, "%s: walked into cliff" % label)
				assert_false(game.island.is_cliff(cell), label)
		game.free()


func test_moves_on_cliff_at_climb_speed() -> void:
	var game := _enter(true)
	var c := _cliff_run(game.island, Vector2i(1, 0), 3)
	assert_ne(c, Vector2i(-1, -1), "no horizontal cliff run")
	await _teleport(game, c)
	var p := game.player()
	assert_true(game.climber().is_climbing())
	var start := p.global_position
	Input.action_press(RIGHT)
	await wait_physics_frames(15)
	Input.action_release(RIGHT)
	var moved := p.global_position.x - start.x
	var expected := ClimbingConfig.load_default().climb_speed * 15.0 / Engine.physics_ticks_per_second
	assert_almost_eq(moved, expected, expected * 0.25, "climb speed on cliff")
	assert_true(game.island.is_cliff(view_cell(game)), "still on the cliff")


func test_stamina_shows_drains_holds_and_refills() -> void:
	var game := _enter(true)
	var view := game.stamina_view()
	var stamina := game.climber().stamina
	var c := _cliff_run(game.island, Vector2i(1, 0), 3)
	await _teleport(game, c - Vector2i(1, 0))
	await wait_process_frames(2)
	assert_false(view.visible, "hidden off cliff when full")
	await _teleport(game, c)
	await wait_process_frames(2)
	assert_true(view.visible, "shown on cliff")
	assert_eq(stamina.current, stamina.config.max_stamina)
	Input.action_press(RIGHT)
	await wait_physics_frames(15)
	Input.action_release(RIGHT)
	await wait_physics_frames(2)
	var after_move := stamina.current
	assert_lt(after_move, stamina.config.max_stamina, "drains while moving on cliff")
	await wait_process_frames(2)
	assert_almost_eq(view.fill_ratio(), stamina.fraction(), 0.01, "bar follows stamina")
	await wait_physics_frames(30)
	assert_true(game.climber().is_climbing())
	assert_eq(stamina.current, after_move, "does not drain while standing still")
	await _teleport(game, c - Vector2i(1, 0))
	await wait_physics_frames(10)
	assert_gt(stamina.current, after_move, "refills off cliff")
	stamina.current = stamina.config.max_stamina
	await wait_process_frames(2)
	assert_false(view.visible, "hidden again once full off cliff")


func test_bar_color_green_orange_red() -> void:
	var game := _enter(true)
	var view := game.stamina_view()
	var cfg := game.climber().config
	await _teleport(game, _cliff_run(game.island, Vector2i(1, 0), 3))
	var colors := []
	for f in [1.0, (cfg.orange_below + cfg.red_below) / 2.0, cfg.red_below / 2.0]:
		game.climber().stamina.current = cfg.max_stamina * f
		await wait_process_frames(2)
		assert_true(view.visible)
		colors.append(view.fill_color())
	assert_eq(colors, [StaminaView.ZONE_COLORS[Stamina.Zone.GREEN], StaminaView.ZONE_COLORS[Stamina.Zone.ORANGE],
		StaminaView.ZONE_COLORS[Stamina.Zone.RED]])
	assert_ne(colors[0], colors[1])
	assert_ne(colors[1], colors[2])


func test_falls_only_after_grace_then_lands_below_with_damage() -> void:
	var game := _enter(true)
	var climber := game.climber()
	var cfg: ClimbingConfig = climber.config.duplicate()
	cfg.drain_per_second = 100.0
	cfg.grace = 15.0
	climber.config = cfg
	climber.stamina = Stamina.new(cfg)
	var c := _cliff_run(game.island, Vector2i(1, 0), 3)
	await _teleport(game, c)
	var p := game.player()
	var hp := p.health.current
	climber.stamina.current = 5.0
	var emptied := -1
	var fell := -1
	var at_fall := []
	climber.fell.connect(func() -> void: at_fall.append(climber.stamina.overdraw))
	Input.action_press(RIGHT)
	for i in 40:
		await wait_physics_frames(1)
		if emptied < 0 and climber.stamina.current == 0.0:
			emptied = i
		if climber.is_falling():
			fell = i
			break
	Input.action_release(RIGHT)
	assert_gt(emptied, -1, "stamina ran out")
	assert_gt(fell, emptied, "does not fall the moment stamina hits 0")
	assert_eq(at_fall.size(), 1)
	var step := cfg.drain_per_second / Engine.physics_ticks_per_second
	assert_gt(at_fall[0], cfg.grace, "falls only once past the grace")
	assert_lte(at_fall[0], cfg.grace + step + 0.001, "falls on the step that passes the grace")
	assert_eq(p.health.current, hp, "no damage until landing")
	# 떨어지는 동안 입력은 먹지 않고 곧장 아래로.
	var from := view_cell(game)
	var land: Vector2i = climber.landing_cell(from)
	assert_ne(land, Climber.NO_CELL)
	assert_gt(land.y, from.y)
	assert_eq(land.x, from.x)
	var x := p.global_position.x
	Input.action_press(RIGHT)
	for i in 240:
		await wait_physics_frames(1)
		if not climber.is_falling():
			break
		assert_eq(p.global_position.x, x, "no sideways control while falling")
	Input.action_release(RIGHT)
	assert_false(climber.is_falling(), "landed")
	assert_eq(view_cell(game), land, "landed on the first walkable cell below")
	assert_false(game.island.is_blocked(view_cell(game)))
	assert_eq(p.health.current, hp - cfg.fall_damage, "fall damage on landing")


func test_taking_off_spikes_on_cliff_drops() -> void:
	var game := _enter(true)
	await _teleport(game, _cliff_run(game.island, Vector2i(1, 0), 3))
	assert_true(game.player().equipment.unequip(EquipmentConfig.FEET))
	await wait_physics_frames(2)
	assert_true(game.climber().is_falling() or not game.island.is_cliff(view_cell(game)))


func view_cell(game: GameScene) -> Vector2i:
	return game.island_view().world_to_cell(game.player().global_position)


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
