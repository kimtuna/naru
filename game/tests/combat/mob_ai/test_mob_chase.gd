extends "res://tests/combat/mob_ai/mob_test_base.gd"
## G-009 6단계 — 몹 기본 AI: 플레이어를 발견하면 쫓아와 공격한다.
## 발견 거리 밖이면 가만히 있고, 놓침 거리 밖으로 멀어지면 쫓기를 멈춘다.


func test_ai_values_are_consistent() -> void:
	var ai := _ai()
	assert_not_null(ai, "mob_config.tres loads")
	assert_gt(ai.sight_radius, ai.attack_range)
	assert_gt(ai.lose_radius, ai.sight_radius, "losing is farther than spotting")
	assert_gt(ai.move_speed, 0.0)
	assert_gt(ai.attack_damage, 0.0)
	assert_gt(ai.attack_interval, 0.0)
	# 몹 몸(12)과 캐릭터 몸(12)이 닿는 중심 거리는 12 — 닿은 채로 때릴 수 있어야 한다.
	assert_gt(ai.attack_range, 12.0, "a mob touching the player is in attack range")


func test_mob_ignores_a_player_out_of_sight() -> void:
	var game := _enter_open()
	var me := game.player().global_position
	var start := me + Vector2.RIGHT * (_ai().sight_radius + 20.0)
	var mob: Mob = game.mob_spawner().spawn(start)[0]
	await wait_physics_frames(30)
	assert_eq(mob.state, Mob.State.IDLE)
	assert_null(mob.target)
	assert_almost_eq(mob.global_position.distance_to(start), 0.0, 0.5, "an idle mob stays put")
	assert_eq(game.player().health.current, game.player().health.max_health)
	await _leave_physics_frame()


func test_mob_spots_chases_and_attacks_the_player() -> void:
	var game := _enter_open()
	var player := game.player()
	var me := player.global_position
	var ai := _ai()
	var start := me + Vector2.LEFT * (ai.sight_radius - 10.0)
	var mob: Mob = game.mob_spawner().spawn(start)[0]
	var hits := []
	mob.attacked.connect(func(t: Node2D, d: float) -> void: hits.append([t, d]))
	await wait_physics_frames(5)
	assert_eq(mob.target, player, "the player in sight is spotted")
	assert_eq(mob.state, Mob.State.CHASE)
	assert_lt(mob.global_position.distance_to(me), start.distance_to(me), "the mob comes closer")
	# 다가오는 데 걸리는 시간 + 여유.
	var travel := (start.distance_to(me) - ai.attack_range) / ai.move_speed
	var reached := await _wait_until(func() -> bool: return hits.size() > 0, _frames(travel + 1.0))
	assert_true(reached, "the mob reaches the player and attacks")
	assert_eq(mob.state, Mob.State.ATTACK)
	assert_lte(mob.global_position.distance_to(player.global_position), ai.attack_range + 0.5)
	assert_almost_eq(player.health.current, player.health.max_health - ai.attack_damage, 0.001,
		"one attack deals attack_damage")
	if hits.size() > 0:
		assert_eq(hits[0][0], player)
		assert_eq(hits[0][1], ai.attack_damage)
	# 붙어 있는 동안 간격마다 계속 때린다 — 한 간격 안에 두 번 때리지 않는다.
	await wait_physics_frames(_frames(ai.attack_interval * 0.5))
	assert_eq(hits.size(), 1, "no second hit before the interval")
	var again := await _wait_until(func() -> bool: return hits.size() >= 2, _frames(ai.attack_interval))
	assert_true(again, "the mob keeps attacking every interval")
	assert_almost_eq(player.health.current, player.health.max_health - ai.attack_damage * 2.0, 0.001)
	await _leave_physics_frame()


func test_mob_follows_a_moving_player() -> void:
	var game := _enter_open()
	var player := game.player()
	var mob: Mob = game.mob_spawner().spawn(player.global_position + Vector2.UP * 40.0)[0]
	await wait_physics_frames(3)
	assert_eq(mob.target, player)
	# 캐릭터가 발견 거리 안에서 옆으로 옮겨 가면 몹도 그쪽으로 방향을 튼다.
	player.global_position += Vector2.RIGHT * 40.0
	var before := mob.global_position
	await wait_physics_frames(10)
	assert_gt(mob.global_position.x, before.x + 1.0, "the mob turns toward the player's new spot")
	assert_eq(mob.state, Mob.State.CHASE)
	await _leave_physics_frame()


func test_mob_gives_up_beyond_lose_radius() -> void:
	var game := _enter_open()
	var player := game.player()
	var ai := _ai()
	var mob: Mob = game.mob_spawner().spawn(player.global_position + Vector2.DOWN * 40.0)[0]
	await wait_physics_frames(3)
	assert_eq(mob.state, Mob.State.CHASE)
	# 발견 거리보다 멀지만 놓침 거리 안 — 계속 쫓는다.
	player.global_position = mob.global_position + Vector2.UP * (ai.sight_radius + ai.lose_radius) / 2.0
	await wait_physics_frames(3)
	assert_eq(mob.target, player, "still chasing between sight and lose radius")
	# 놓침 거리 밖 — 멈춘다.
	player.global_position = mob.global_position + Vector2.UP * (ai.lose_radius + 20.0)
	await wait_physics_frames(3)
	assert_null(mob.target, "the player is lost")
	assert_eq(mob.state, Mob.State.IDLE)
	var here := mob.global_position
	await wait_physics_frames(10)
	assert_almost_eq(mob.global_position.distance_to(here), 0.0, 0.5, "the mob stops chasing")
	await _leave_physics_frame()


func test_dead_mob_does_not_attack() -> void:
	var game := _enter_open()
	var player := game.player()
	var mob: Mob = game.mob_spawner().spawn(player.global_position + Vector2.RIGHT * 14.0)[0]
	mob.take_damage(mob.health.max_health)
	await wait_physics_frames(_frames(_ai().attack_interval) + 2)
	assert_false(is_instance_valid(mob), "a dead mob is gone")
	assert_eq(player.health.current, player.health.max_health, "a dead mob never hits")
	await _leave_physics_frame()
