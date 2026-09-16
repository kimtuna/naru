extends "res://tests/life/harvest/harvest_test_base.gd"
## G-009 4단계 — 도구 근접 공격: 좌클릭 평타로 몹을 치면 피해가 들어간다.
## 맨손 포함 손에 든 것마다 공격 수치가 있고, 채취와 같은 판정 경로(Swinger → SwingAim)를 쓴다.

const MOB_SCENE := "res://combat/mob_ai/mob.tscn"
const WOOD := {"id": "wood", "count": 3}


func world_seed() -> int:
	return 777


func _weapon_cfg() -> WeaponConfig:
	return WeaponConfig.load_default()


func _mob(game: GameScene, at: Vector2) -> Mob:
	var mob: Mob = (load(MOB_SCENE) as PackedScene).instantiate()
	mob.position = at
	game.mobs().add_child(mob)
	return mob


## 둘레 손 닿는 범위에 자원이 없는 칸 — 몹 말고는 맞을 것이 없다.
func _free_spot(game: GameScene) -> Vector2i:
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


func _click_toward(pos: Vector2) -> void:
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(pos)
	_click(true, screen_mid)
	await wait_physics_frames(2)
	_click(false, screen_mid)
	await wait_physics_frames(1)


func test_every_held_thing_has_an_attack_value() -> void:
	var cfg := _weapon_cfg()
	assert_not_null(cfg, "weapon_config.tres loads")
	assert_gt(cfg.attack_of(null), 0.0, "bare hand has an attack")
	for id in [HarvestConfig.AXE, HarvestConfig.PICKAXE]:
		assert_true(cfg.attacks.has(str(id)), "tool %s has its own attack entry" % id)
		assert_gt(cfg.attack_of({"id": str(id), "count": 1}), 0.0)
	assert_gt(cfg.attack_of(WOOD), 0.0, "any other item still has an attack")
	assert_eq(cfg.attack_of({"id": "axe", "count": 1}), float(cfg.attacks["axe"]))
	assert_eq(cfg.attack_of(WOOD), cfg.other_attack)
	assert_eq(cfg.attack_of(null), cfg.hand_attack)
	assert_gt(cfg.mob_radius, 0.0)


func test_left_click_on_mob_deals_the_held_attack() -> void:
	_hide_gut_layer()
	var game := _enter()
	_stand(game, _free_spot(game))
	var me := game.player().global_position
	var cfg := _weapon_cfg()
	var hits := []
	game.melee().mob_hit.connect(func(m: Mob, d: float) -> void: hits.append([m, d]))
	for item in [null, AXE, PICKAXE, WOOD]:
		var mob := _mob(game, me + Vector2.RIGHT * 20.0)
		_hold(game, item)
		var before := mob.health.current
		await _click_toward(mob.global_position)
		var expected := cfg.attack_of(item)
		assert_almost_eq(mob.health.current, before - expected, 0.001,
			"holding %s, a left click deals %s" % [item, expected])
		assert_eq(hits.size(), 1, "one hit per click")
		if hits.size() == 1:
			assert_eq(hits[0][0], mob)
			assert_eq(hits[0][1], expected)
		hits.clear()
		mob.free()
	await _leave_physics_frame()


func test_axe_and_pickaxe_kill_a_mob_through_swings() -> void:
	var game := _enter()
	_stand(game, _free_spot(game))
	var me := game.player().global_position
	var deaths := []
	for item in [AXE, PICKAXE]:
		deaths.clear()
		var mob := _mob(game, me + Vector2.LEFT * 18.0)
		mob.died.connect(func(m: Mob) -> void: deaths.append(m))
		_hold(game, item)
		Pointer.simulate(mob.global_position)
		var need := ceili(mob.health.max_health / _weapon_cfg().attack_of(item))
		for i in need:
			var hit := game.swinger().swing()
			assert_not_null(hit, "the mob is hit")
			if hit:
				assert_eq(hit.what, mob)
		assert_true(mob.is_dead(), "%s kills the mob in %d swings" % [item, need])
		assert_eq(deaths.size(), 1, "died is emitted once")
		await wait_process_frames(1)
		assert_false(is_instance_valid(mob), "dead mob is gone")
		assert_null(game.swinger().swing(), "nothing left to hit")
	await _leave_physics_frame()


func test_cursor_need_not_be_on_the_mob_but_reach_and_facing_count() -> void:
	var game := _enter()
	_stand(game, _free_spot(game))
	var me := game.player().global_position
	var reach := _swing_cfg().reach_px(game.island_view().tile_px())
	var front := _mob(game, me + Vector2.RIGHT * 16.0)
	var behind := _mob(game, me + Vector2.LEFT * 16.0)
	var far := _mob(game, me + Vector2.UP * (reach + 4.0))
	_hold(game, AXE)
	# 커서는 몹보다 훨씬 멀리, 조금 비껴 있다.
	Pointer.simulate(me + Vector2.RIGHT.rotated(0.3) * 200.0)
	var hit := game.swinger().swing()
	assert_not_null(hit)
	if hit:
		assert_eq(hit.what, front, "the mob in front is hit")
	assert_lt(front.health.current, front.health.max_health)
	assert_eq(behind.health.current, behind.health.max_health, "the mob behind is not hit")
	Pointer.simulate(far.global_position)
	var miss := game.swinger().swing()
	if miss:
		assert_ne(miss.what, far, "a mob beyond reach is not hit")
	assert_eq(far.health.current, far.health.max_health)


func test_mob_and_resource_share_the_same_pick() -> void:
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var me := game.player().global_position
	var tree := game.island_view().cell_center(found[0])
	# 나무보다 가까이, 같은 방향에 몹 — 앞의 몹이 나무를 가린다.
	var mob := _mob(game, me + (tree - me) * 0.4)
	Pointer.simulate(tree)
	var hit := game.swinger().swing()
	assert_not_null(hit)
	if hit:
		assert_eq(hit.what, mob, "the nearer mob on the line is hit first")
	assert_lt(mob.health.current, mob.health.max_health)
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE, "the tree behind is untouched")
	mob.free()
	var next := game.swinger().swing()
	assert_not_null(next)
	if next:
		assert_eq(next.what, found[0], "with the mob gone, the tree is hit")


func test_no_mob_damage_while_a_window_is_open() -> void:
	_hide_gut_layer()
	var game := _enter()
	_stand(game, _free_spot(game))
	var mob := _mob(game, game.player().global_position + Vector2.RIGHT * 20.0)
	_hold(game, AXE)
	game.inventory_view().set_open(true)
	await _click_toward(mob.global_position)
	assert_eq(mob.health.current, mob.health.max_health, "no swing while the bag is open")
	game.inventory_view().set_open(false)
	await _leave_physics_frame()
