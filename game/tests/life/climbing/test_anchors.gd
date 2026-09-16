extends "res://tests/craft/stations/station_test_base.gd"
## G-014 3단계 — 앵커: 레시피가 있고, 들고 절벽 칸에 우클릭하면 달리며 하나가 준다.
## 앵커가 달린 칸에 있으면 기력이 회복되고, 달린 앵커는 월드 저장에 남는다.

const Cliffs := preload("res://tests/world/island/test_island_cliffs.gd")
const RIGHT := Vector2i(1, 0)


func world_seed() -> int:
	return 20260916


func _anchors(count: int) -> Dictionary:
	return {"id": Anchors.ANCHOR, "count": count}


## 스파이크를 신은 캐릭터로 바꿔 저장한다 (_enter 전에).
func _wear_spikes() -> void:
	var ch := Session.store.load_character(0)
	ch.equipment[EquipmentConfig.FEET] = {"id": EquipmentConfig.SPIKES, "count": 1}
	assert_eq(Session.store.save_character(0, ch), OK)


## 오른쪽이 절벽인 걸을 수 있는 칸에 선다 — 그 절벽 칸.
func _stand_left_of_cliff(game: GameScene) -> Vector2i:
	var cliff := Cliffs.approach(game.island, RIGHT, true)
	assert_ne(cliff, Vector2i(-1, -1), "setup: no cliff near spawn")
	_stand(game, cliff - RIGHT)
	assert_false(game.island.is_cliff(cliff - RIGHT), "setup: standing off the cliff")
	return cliff


# --- 레시피 ---

func test_anchor_has_a_recipe_made_from_raw_materials() -> void:
	var book := RecipeBook.load_default()
	var r := book.recipe_for(Anchors.ANCHOR)
	assert_false(r.is_empty(), "no recipe makes an anchor")
	assert_eq(r.output.id, Anchors.ANCHOR)
	assert_gt(r.output.count, 0)
	assert_true(book.stations.has(r.station))
	var d := book.depth_of(Anchors.ANCHOR)
	assert_gt(d, 0, "anchor cannot be made from raw materials")
	assert_true(d <= RecipeBook.MAX_DEPTH)
	assert_ne(tr("ITEM_ANCHOR"), "ITEM_ANCHOR", "anchor has a translated name")


# --- 달기 ---

func test_right_click_on_cliff_attaches_and_uses_one() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := _stand_left_of_cliff(game)
	_hold(game, _anchors(3))
	assert_false(game.anchors().has_anchor(cliff))
	await _right_click_cell(game, cliff)
	assert_true(game.anchors().has_anchor(cliff), "right click with an anchor on a cliff attaches it")
	assert_eq(game.anchors().cells(), [cliff] as Array[Vector2i])
	assert_eq(_held(game), _anchors(2), "one anchor is used up")
	assert_eq(game.swinger().swing_count, 0, "attaching is not a swing")
	await _right_click_cell(game, cliff)
	assert_eq(_held(game), _anchors(2), "a cell that already has an anchor does not take another")
	await _leave_physics_frame()


func test_last_anchor_empties_the_slot() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := _stand_left_of_cliff(game)
	_hold(game, _anchors(1))
	await _right_click_cell(game, cliff)
	assert_true(game.anchors().has_anchor(cliff))
	assert_null(_held(game), "the last anchor leaves the hand empty")
	await _leave_physics_frame()


func test_only_cliff_cells_take_an_anchor() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := _stand_left_of_cliff(game)
	var ground := cliff - RIGHT * 2
	assert_false(game.island.is_cliff(ground))
	_hold(game, _anchors(3))
	await _right_click_cell(game, ground)
	assert_false(game.anchors().has_anchor(ground), "not on ground")
	assert_eq(_held(game), _anchors(3))
	assert_true(game.anchors().cells().is_empty())
	await _leave_physics_frame()


func test_only_the_anchor_attaches_and_reach_is_needed() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := _stand_left_of_cliff(game)
	_hold(game, PICKAXE)
	await _right_click_cell(game, cliff)
	assert_false(game.anchors().has_anchor(cliff), "another item does not attach an anchor")
	_stand(game, cliff - RIGHT * 6)
	_hold(game, _anchors(3))
	await _right_click_cell(game, cliff)
	assert_false(game.anchors().has_anchor(cliff), "out of reach")
	assert_eq(_held(game), _anchors(3))
	await _leave_physics_frame()


# --- 기력 회복 ---

func test_stamina_recovers_on_an_anchored_cell() -> void:
	_wear_spikes()
	var game := _enter()
	var cliff := _stand_left_of_cliff(game)
	var stamina := game.climber().stamina
	_stand(game, cliff)
	await wait_physics_frames(2)
	assert_true(game.climber().is_climbing(), "setup: on the cliff")
	stamina.current = 10.0
	await wait_physics_frames(20)
	assert_eq(stamina.current, 10.0, "no recovery on a bare cliff cell")
	game.anchors().attach(cliff)
	await wait_physics_frames(20)
	assert_true(game.climber().is_climbing(), "still hanging on the cliff")
	var expected := 10.0 + stamina.config.anchor_regen_per_second * 20.0 / Engine.physics_ticks_per_second
	assert_almost_eq(stamina.current, expected, 1.0, "recovers on the anchored cell")
	await _leave_physics_frame()


func test_anchor_recovery_beats_drain_and_clears_overdraw() -> void:
	var cfg := ClimbingConfig.load_default()
	var s := Stamina.new(cfg)
	s.current = 0.0
	s.overdraw = cfg.grace * 0.5
	assert_false(s.tick(0.5, true, true, true), "never falls on an anchored cell")
	assert_almost_eq(s.current, cfg.anchor_regen_per_second * 0.5, 0.001, "moving on it still recovers")
	assert_eq(s.overdraw, 0.0)
	s.current = cfg.max_stamina - 0.1
	s.tick(1.0, true, false, true)
	assert_eq(s.current, cfg.max_stamina, "stops at the max")
	s.current = 10.0
	s.tick(0.5, true, true, false)
	assert_lt(s.current, 10.0, "still drains without an anchor")
	assert_gt(cfg.anchor_regen_per_second, 0.0)


# --- 저장 ---

func test_anchors_are_saved_with_the_world() -> void:
	_hide_gut_layer()
	var game := _enter()
	var cliff := _stand_left_of_cliff(game)
	_hold(game, _anchors(2))
	await _right_click_cell(game, cliff)
	assert_true(game.anchors().has_anchor(cliff))
	game.store_world_state()
	assert_eq(game.world.anchors, [cliff])
	assert_eq(Session.store.save_world(_world_id, game.world), OK)
	game.free()
	var again := _enter()
	assert_true(again.anchors().has_anchor(cliff), "the anchor is still there after loading")
	assert_eq(again.climber().anchors, again.anchors(), "loaded anchors feed the climber")
	var copy := WorldData.from_dict(again.world.to_dict())
	assert_eq(copy.anchors, [cliff])
	assert_eq(WorldData.from_dict({"anchors": [cliff, "x", 3]}).anchors, [cliff], "bad entries are dropped")
	assert_true(WorldData.from_dict({}).anchors.is_empty(), "old saves have no anchors")
	await _leave_physics_frame()
