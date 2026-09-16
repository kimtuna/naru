extends "res://tests/life/harvest/harvest_test_base.gd"
## G-009 5단계 — 총과 투사체: 총은 Pointer 방향으로 투사체를 쏘고 탄약을 쓴다. 탄약이 없으면 쏘지 않는다.
## 투사체가 몹에 맞으면 피해가 들어가고 사라진다.

const MOB_SCENE := "res://combat/mob_ai/mob.tscn"
const GUN := {"id": "gun", "count": 1}


func world_seed() -> int:
	return 777


func _gun_cfg() -> GunConfig:
	return GunConfig.load_default()


func _mob(game: GameScene, at: Vector2) -> Mob:
	var mob: Mob = (load(MOB_SCENE) as PackedScene).instantiate()
	mob.position = at
	game.mobs().add_child(mob)
	return mob


func _ammo(game: GameScene) -> int:
	return game.player().hotbar.inventory.count_of(_gun_cfg().ammo_id)


func _give_ammo(game: GameScene, count: int) -> void:
	assert_eq(game.player().hotbar.inventory.add({"id": _gun_cfg().ammo_id, "count": count}), 0)


func _shots(game: GameScene) -> Array:
	return game.projectiles().get_children().filter(
		func(p: Node) -> bool: return p is Projectile and not p.is_queued_for_deletion())


## 둘레에 자원이 없는 칸 — 휘둘렀다면 맞을 것이 몹뿐이다.
func _free_spot(game: GameScene) -> Vector2i:
	var s := game.island.spawn()
	for r in range(0, 40):
		for y in range(s.y - r, s.y + r + 1):
			for x in range(s.x - r, s.x + r + 1):
				var c := Vector2i(x, y)
				var clear := true
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						if game.island.is_blocked(c + Vector2i(dx, dy)):
							clear = false
				if clear:
					return c
	fail_test("no clear spot")
	return s


func _ready_game(ammo: int) -> GameScene:
	var game := _enter()
	_stand(game, _free_spot(game))
	_hold(game, GUN)
	if ammo > 0:
		_give_ammo(game, ammo)
	return game


func _click_toward(pos: Vector2) -> void:
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(pos)
	_click(true, screen_mid)
	await wait_physics_frames(1)
	_click(false, screen_mid)
	await wait_physics_frames(1)


func test_gun_config_has_stats_and_ammo() -> void:
	var cfg := _gun_cfg()
	assert_not_null(cfg, "gun_config.tres loads")
	assert_true(cfg.is_gun(GUN), "the crafted gun item is a gun")
	assert_false(cfg.is_gun(AXE), "an axe is not a gun")
	assert_false(cfg.is_gun(null), "bare hand is not a gun")
	for key in ["damage", "speed", "range", "interval"]:
		assert_gt(cfg.stat(GUN, key), 0.0, "gun has %s" % key)
	assert_eq(cfg.stat(AXE, "damage"), 0.0)
	assert_eq(cfg.ammo_id, "ammo", "ammo is the crafted ammo item")
	assert_gt(cfg.ammo_per_shot, 0)
	assert_gt(cfg.hit_radius, 0.0)


func test_fire_goes_toward_pointer_and_uses_ammo() -> void:
	var game := _ready_game(10)
	var me := game.player().global_position
	var cfg := _gun_cfg()
	var left := 10
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2(1, 1).normalized(), Vector2(-3, 1).normalized()]:
		Pointer.simulate(me + dir * 50.0)
		var p := game.gunner().fire(GUN)
		assert_not_null(p, "a shot is fired toward %s" % dir)
		if p == null:
			continue
		left -= cfg.ammo_per_shot
		assert_eq(_ammo(game), left, "one shot uses ammo")
		assert_true(p.direction.is_equal_approx(dir), "flies toward the pointer %s, got %s" % [dir, p.direction])
		assert_eq(p.get_parent(), game.projectiles())
		assert_almost_eq(p.global_position.distance_to(me), cfg.muzzle_offset, 0.01, "starts at the shooter")
		var start := p.global_position
		p.advance(20.0)
		assert_true((p.global_position - start).normalized().is_equal_approx(dir), "moves along the pointer direction")
		assert_almost_eq(p.global_position.distance_to(start), 20.0, 0.01)
		p.free()


func test_left_click_with_gun_shoots_instead_of_swinging() -> void:
	_hide_gut_layer()
	var game := _ready_game(5)
	var me := game.player().global_position
	var mob := _mob(game, me + Vector2.RIGHT * 20.0)
	var swings := game.swinger().swing_count
	var fired := []
	game.gunner().fired.connect(func(p: Projectile) -> void: fired.append(p))
	await _click_toward(me + Vector2.UP * 80.0)
	assert_eq(fired.size(), 1, "a left click fires once")
	assert_eq(_ammo(game), 5 - _gun_cfg().ammo_per_shot)
	assert_eq(game.swinger().swing_count, swings, "holding a gun, a click does not swing")
	assert_eq(mob.health.current, mob.health.max_health, "the mob beside is not swung at")
	if fired.size() == 1 and is_instance_valid(fired[0]):
		assert_true(fired[0].direction.is_equal_approx(Vector2.UP), "the click shot flies toward the pointer")
	await _leave_physics_frame()


func test_holding_click_fires_until_ammo_runs_out() -> void:
	_hide_gut_layer()
	var game := _ready_game(2)
	var me := game.player().global_position
	var fired := []
	var dry := []
	game.gunner().fired.connect(func(p: Projectile) -> void: fired.append(p))
	game.gunner().dry_fired.connect(func() -> void: dry.append(true))
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(me + Vector2.DOWN * 80.0)
	_click(true, screen_mid)
	var frames := ceili(_gun_cfg().stat(GUN, "interval") * Engine.physics_ticks_per_second) * 4 + 4
	await wait_physics_frames(frames)
	_click(false, screen_mid)
	await wait_physics_frames(1)
	assert_eq(fired.size(), 2, "two rounds, two shots")
	assert_eq(_ammo(game), 0)
	assert_gt(dry.size(), 0, "then the trigger clicks empty")
	await _leave_physics_frame()


func test_no_ammo_no_shot() -> void:
	_hide_gut_layer()
	var game := _ready_game(0)
	var me := game.player().global_position
	var mob := _mob(game, me + Vector2.RIGHT * 20.0)
	var before := game.player().hotbar.inventory.character.inventory.duplicate(true)
	var swings := game.swinger().swing_count
	Pointer.simulate(mob.global_position)
	assert_null(game.gunner().fire(GUN), "no ammo, no shot")
	await _click_toward(mob.global_position)
	assert_eq(_shots(game).size(), 0, "no projectile without ammo")
	assert_eq(game.swinger().swing_count, swings, "an empty gun does not swing either")
	assert_eq(mob.health.current, mob.health.max_health)
	assert_eq(game.player().hotbar.inventory.character.inventory, before, "inventory untouched")
	# 다른 아이템이 있어도 탄약이 아니면 못 쏜다.
	game.player().hotbar.inventory.add({"id": "wood", "count": 5})
	assert_null(game.gunner().fire(GUN))
	assert_eq(game.player().hotbar.inventory.count_of("wood"), 5)
	await _leave_physics_frame()


func test_no_shot_while_a_window_is_open() -> void:
	_hide_gut_layer()
	var game := _ready_game(3)
	game.inventory_view().set_open(true)
	await _click_toward(game.player().global_position + Vector2.RIGHT * 40.0)
	assert_eq(_shots(game).size(), 0, "no shot while the bag is open")
	assert_eq(_ammo(game), 3)
	game.inventory_view().set_open(false)
	await _leave_physics_frame()


func test_projectile_hits_mob_deals_damage_and_disappears() -> void:
	var game := _ready_game(3)
	var me := game.player().global_position
	var cfg := _gun_cfg()
	var near := _mob(game, me + Vector2.RIGHT * 60.0)
	var far := _mob(game, me + Vector2.RIGHT * 90.0)
	var hits := []
	Pointer.simulate(far.global_position)
	var p := game.gunner().fire(GUN)
	assert_not_null(p)
	p.hit_mob.connect(func(m: Mob, d: float) -> void: hits.append([m, d]))
	var frames := ceili(cfg.stat(GUN, "range") / cfg.stat(GUN, "speed") * Engine.physics_ticks_per_second) + 5
	await wait_physics_frames(frames)
	var damage := cfg.stat(GUN, "damage")
	assert_almost_eq(near.health.current, near.health.max_health - damage, 0.001, "the first mob on the line takes the gun's damage")
	assert_eq(far.health.current, far.health.max_health, "the shot stops at the first mob")
	assert_eq(hits.size(), 1, "hits once")
	if hits.size() == 1:
		assert_eq(hits[0][0], near)
		assert_eq(hits[0][1], damage)
	assert_false(is_instance_valid(p), "the projectile is gone after hitting")
	assert_eq(_shots(game).size(), 0)
	await _leave_physics_frame()


func test_projectile_that_misses_leaves_mob_alone_and_expires_at_range() -> void:
	var game := _ready_game(1)
	var me := game.player().global_position
	var cfg := _gun_cfg()
	var aside := _mob(game, me + Vector2(60.0, cfg.hit_radius + 6.0))
	var beyond := _mob(game, me + Vector2.RIGHT * (cfg.stat(GUN, "range") + cfg.muzzle_offset + cfg.hit_radius + 10.0))
	Pointer.simulate(me + Vector2.RIGHT * 50.0)
	var p := game.gunner().fire(GUN)
	assert_not_null(p)
	var start := p.global_position
	var frames := ceili(cfg.stat(GUN, "range") / cfg.stat(GUN, "speed") * Engine.physics_ticks_per_second) + 5
	await wait_physics_frames(frames)
	assert_eq(aside.health.current, aside.health.max_health, "a mob off the line is not hit")
	assert_eq(beyond.health.current, beyond.health.max_health, "a mob beyond range is not hit")
	assert_false(is_instance_valid(p), "the projectile disappears after its range")
	assert_eq(_shots(game).size(), 0)
	# 사거리 끝에서 사라진다 — 그 전에 사라지지 않는다.
	var q := Projectile.create(Vector2.RIGHT, GUN, cfg, game.mobs())
	game.projectiles().add_child(q)
	q.global_position = start
	q.advance(cfg.stat(GUN, "range") - 1.0)
	assert_false(q.is_queued_for_deletion(), "still flying before its range")
	q.advance(5.0)
	assert_true(q.is_queued_for_deletion(), "gone once range is reached")
	assert_almost_eq(q.traveled, cfg.stat(GUN, "range"), 0.001)
	await _leave_physics_frame()


func test_fast_projectile_does_not_skip_a_mob() -> void:
	var game := _ready_game(1)
	var me := game.player().global_position
	var cfg := _gun_cfg()
	var mob := _mob(game, me + Vector2.LEFT * 40.0)
	Pointer.simulate(mob.global_position)
	var p := game.gunner().fire(GUN)
	assert_not_null(p)
	var hit := p.advance(cfg.stat(GUN, "range"))
	assert_eq(hit, mob, "one long step still hits the mob it passes")
	assert_almost_eq(mob.health.current, mob.health.max_health - cfg.stat(GUN, "damage"), 0.001)
	assert_true(p.is_queued_for_deletion())
	await _leave_physics_frame()


func test_dead_mob_is_not_hit_and_shots_can_kill() -> void:
	var game := _ready_game(50)
	var me := game.player().global_position
	var cfg := _gun_cfg()
	var mob := _mob(game, me + Vector2.RIGHT * 30.0)
	var deaths := []
	mob.died.connect(func(m: Mob) -> void: deaths.append(m))
	Pointer.simulate(mob.global_position)
	var need := ceili(mob.health.max_health / cfg.stat(GUN, "damage"))
	for i in need:
		var p := game.gunner().fire(GUN)
		assert_eq(p.advance(100.0), mob, "shot %d hits" % i)
	assert_true(mob.is_dead(), "the gun kills the mob in %d shots" % need)
	assert_eq(deaths.size(), 1)
	var after := game.gunner().fire(GUN)
	assert_null(after.advance(100.0), "a dead mob is not hit again")
	await wait_process_frames(1)
	assert_false(is_instance_valid(mob), "dead mob is gone")
