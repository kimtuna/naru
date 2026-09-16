extends "res://tests/life/harvest/harvest_test_base.gd"
## G-009 1단계 — 체력 · 피해 · 죽음 (spec/08_combat/damage-death.md).
## 캐릭터와 몹에 체력이 있고 0 이 되면 죽는다 · 죽으면 스폰 지점에서 다시 시작한다.

const MOB_SCENE := "res://combat/mob_ai/mob.tscn"


func _dmg_cfg() -> DamageConfig:
	return DamageConfig.load_default()


func _mob(game: GameScene, at: Vector2) -> Mob:
	var mob: Mob = (load(MOB_SCENE) as PackedScene).instantiate()
	mob.position = at
	game.mobs().add_child(mob)
	return mob


# --- 수치는 한 곳 ---

func test_health_values_live_in_config() -> void:
	var cfg := _dmg_cfg()
	assert_not_null(cfg, "missing " + DamageConfig.DEFAULT_PATH)
	assert_gt(cfg.player_max_health, 0.0)
	assert_gt(cfg.mob_max_health, 0.0)
	for path in ["res://player/player.gd", "res://combat/mob_ai/mob.gd", "res://combat/damage_death/health.gd"]:
		var src := FileAccess.get_file_as_string(path)
		assert_false(src.contains("%.1f" % cfg.player_max_health), path + " hard-codes player health")


# --- 체력 ---

func test_health_drops_and_dies_once_at_zero() -> void:
	var h := Health.new(10.0)
	watch_signals(h)
	assert_false(h.is_dead())
	assert_false(h.damage(4.0), "not dead at 6")
	assert_eq(h.current, 6.0)
	assert_false(h.damage(0.0))
	assert_false(h.damage(-5.0), "negative damage does not heal")
	assert_eq(h.current, 6.0)
	assert_signal_not_emitted(h, "died")
	assert_true(h.damage(6.0), "dies exactly at 0")
	assert_true(h.is_dead())
	assert_eq(h.current, 0.0)
	assert_false(h.damage(3.0), "a dead body does not die again")
	assert_eq(h.current, 0.0, "does not go below 0")
	assert_signal_emit_count(h, "died", 1)


func test_overkill_clamps_to_zero_and_reset_refills() -> void:
	var h := Health.new(10.0)
	h.heal(5.0)
	assert_eq(h.current, 10.0, "heal does not exceed max")
	assert_true(h.damage(25.0))
	assert_eq(h.current, 0.0)
	h.heal(5.0)
	assert_true(h.is_dead(), "healing does not revive")
	h.reset()
	assert_eq(h.current, 10.0)
	assert_false(h.is_dead())


# --- 캐릭터 ---

func test_character_has_full_health_on_enter() -> void:
	var game := _enter()
	var p := game.player()
	assert_eq(p.health.max_health, _dmg_cfg().player_max_health)
	assert_eq(p.health.current, p.health.max_health)
	assert_false(p.health.is_dead())


func test_character_survives_damage_below_max() -> void:
	var game := _enter()
	var p := game.player()
	var away := p.spawn_point + Vector2(64, 0)
	p.global_position = away
	watch_signals(p)
	assert_false(p.take_damage(p.health.max_health - 1.0))
	assert_eq(p.health.current, 1.0)
	assert_eq(p.global_position, away, "still alive — stays put")
	assert_signal_not_emitted(p, "died")


func test_character_dies_at_zero_and_respawns_at_spawn() -> void:
	var game := _enter()
	var p := game.player()
	var spawn := game.island_view().cell_center(game.island.spawn())
	assert_eq(p.spawn_point, spawn, "spawn point is the island spawn cell")
	var away := spawn + Vector2(96, -48)
	p.global_position = away
	watch_signals(p)
	p.take_damage(30.0)
	assert_true(p.take_damage(p.health.max_health), "hits 0 and dies")
	assert_signal_emit_count(p, "died", 1)
	assert_signal_emitted_with_parameters(p, "died", [away])
	assert_signal_emit_count(p, "respawned", 1)
	assert_eq(p.global_position, spawn, "starts again at the spawn point")
	assert_eq(p.health.current, p.health.max_health, "starts again with full health")
	assert_false(p.health.is_dead())


func test_respawned_character_stays_at_spawn_after_physics() -> void:
	var game := _enter()
	var p := game.player()
	p.global_position = p.spawn_point + Vector2(80, 0)
	await wait_physics_frames(1)
	p.take_damage(p.health.max_health * 2.0)
	await wait_physics_frames(2)
	assert_almost_eq(p.global_position, p.spawn_point, Vector2(0.5, 0.5))
	assert_false(p.take_damage(1.0), "alive again — takes damage without dying")
	assert_eq(p.health.current, p.health.max_health - 1.0)


func test_character_can_die_again_after_respawn() -> void:
	var game := _enter()
	var p := game.player()
	watch_signals(p)
	p.take_damage(p.health.max_health)
	p.global_position = p.spawn_point + Vector2(0, 40)
	assert_true(p.take_damage(p.health.max_health), "dies again")
	assert_signal_emit_count(p, "died", 2)
	assert_eq(p.global_position, p.spawn_point)


# --- 몹 ---

func test_mob_has_health_and_dies_at_zero() -> void:
	var game := _enter()
	var mob := _mob(game, game.player().spawn_point + Vector2(40, 0))
	assert_eq(mob.health.max_health, _dmg_cfg().mob_max_health)
	assert_eq(mob.health.current, mob.health.max_health)
	watch_signals(mob)
	assert_false(mob.take_damage(mob.health.max_health - 1.0))
	assert_false(mob.is_dead())
	await wait_physics_frames(1)
	assert_true(is_instance_valid(mob) and mob.is_inside_tree(), "alive mob stays")
	assert_true(mob.take_damage(1.0), "dies at 0")
	assert_true(mob.is_dead())
	assert_signal_emit_count(mob, "died", 1)
	await wait_physics_frames(1)
	assert_false(is_instance_valid(mob), "dead mob is removed from the world")
	assert_eq(game.mobs().get_child_count(), 0)


func test_mob_death_does_not_touch_the_character() -> void:
	var game := _enter()
	var p := game.player()
	var away := p.spawn_point + Vector2(32, 0)
	p.global_position = away
	var mob := _mob(game, away + Vector2(16, 0))
	mob.take_damage(mob.health.max_health)
	assert_eq(p.global_position, away)
	assert_eq(p.health.current, p.health.max_health)
