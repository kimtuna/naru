extends "res://tests/combat/mob_ai/mob_test_base.gd"
## G-009 6단계 — 몹 스폰 위치와 수를 코드에서 정한다 (원정에서 떼로 부르기 위해).


func test_spawn_count_around_a_point() -> void:
	var game := _enter_open()
	var spawner := game.mob_spawner()
	var at := game.player().global_position + Vector2.RIGHT * 300.0
	var seen := []
	spawner.spawned.connect(func(m: Mob) -> void: seen.append(m))
	for count in [1, 5, 13]:
		for m in spawner.alive():
			m.free()
		seen.clear()
		var made := spawner.spawn(at, count)
		assert_eq(made.size(), count, "spawn(at, %d) makes %d mobs" % [count, count])
		assert_eq(seen, made, "spawned is emitted for each")
		assert_eq(spawner.alive().size(), count)
		assert_eq(made[0].global_position, at, "the first mob stands on the point")
		for i in made.size():
			var m := made[i]
			assert_eq(m.get_parent(), game.mobs(), "mobs live under the mobs parent")
			assert_true(m.targets.is_valid(), "spawned mobs know whom to hunt")
			assert_lte(m.global_position.distance_to(at), _ai().spawn_spacing * 3.0 + 0.5,
				"the horde stays around the point")
			for j in range(i + 1, made.size()):
				assert_gte(m.global_position.distance_to(made[j].global_position),
					_ai().spawn_spacing - 0.5, "mobs do not overlap")
	assert_eq(spawner.spawn(at, 0).size(), 0, "zero makes none")
	await _leave_physics_frame()


func test_spawn_at_exact_points() -> void:
	var game := _enter_open()
	var me := game.player().global_position
	var points := [me + Vector2(200, 0), me + Vector2(-200, 50), me + Vector2(0, 220)]
	var made := game.mob_spawner().spawn_at(points)
	assert_eq(made.size(), points.size())
	for i in points.size():
		assert_eq(made[i].global_position, points[i], "mob %d stands where asked" % i)
	await _leave_physics_frame()


func test_spawned_horde_hunts_the_player_and_can_be_fought() -> void:
	var game := _enter_open()
	var player := game.player()
	var ai := _ai()
	var horde := game.mob_spawner().spawn(player.global_position + Vector2.RIGHT * 50.0, 4)
	await wait_physics_frames(3)
	for m in horde:
		assert_eq(m.target, player, "every mob in the horde spots the player")
	var hurt := await _wait_until(
		func() -> bool: return player.health.current < player.health.max_health, _frames(3.0))
	assert_true(hurt, "the horde reaches the player and hurts them")
	# 부른 몹은 근접 공격 대상이다.
	var near := game.melee().targets_near(player.global_position, ai.sight_radius)
	assert_eq(near.size(), horde.size(), "melee sees every spawned mob")
	# 투사체도 맞힌다.
	var shot := Projectile.create(Vector2.RIGHT, {"id": "gun", "count": 1}, GunConfig.load_default(), game.mobs())
	game.projectiles().add_child(shot)
	shot.global_position = horde[0].global_position + Vector2.LEFT * 5.0
	var hit := shot.advance(10.0)
	assert_not_null(hit, "a bullet hits a spawned mob")
	await _leave_physics_frame()
