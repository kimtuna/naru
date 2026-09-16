extends "res://tests/life/harvest/harvest_test_base.gd"
## G-004 3단계 — 실제 좌클릭 입력: 누르면 겨눈 칸을 치고, 쥐고 있으면 이어서 휘두른다.


func test_left_click_harvests_aimed_cell() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.TREE)
	_stand(game, found[1])
	_hold(game, AXE)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	# 겨누지 않은 곳(빈 스폰)을 누르면 아무 일도 없다.
	Pointer.simulate(game.island_view().cell_center(game.island.spawn()))
	_click(true, screen_mid)
	await wait_physics_frames(3)
	_click(false, screen_mid)
	assert_eq(game.island.deposit_at(found[0]), Deposit.TREE)
	Pointer.simulate(game.island_view().cell_center(found[0]))
	_click(true, screen_mid)
	await wait_physics_frames(3)
	_click(false, screen_mid)
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "click with axe must fell the aimed tree")
	assert_eq(_drops_at(game, found[0]).size(), 1)
	await _leave_physics_frame()


func test_holding_click_keeps_swinging_bare_hand() -> void:
	_hide_gut_layer()
	var game := _enter()
	var found := _find(game, Deposit.STONE)
	_stand(game, found[1])
	_hold(game, null)
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(found[0]))
	_click(true, screen_mid)
	await wait_physics_frames(2)
	assert_eq(game.island.deposit_at(found[0]), Deposit.STONE, "bare hand must be slow")
	var cfg := _cfg()
	var swings := ceili(float(cfg.deposit_hp) / cfg.hand_power)
	await wait_seconds(cfg.swing_interval * swings + 0.3)
	_click(false, screen_mid)
	assert_eq(game.island.deposit_at(found[0]), Deposit.NONE, "holding click must keep swinging")
	var here := _drops_at(game, found[0])
	assert_eq(here.size(), 1)
	if here.size() == 1:
		assert_eq(here[0].item_id(), "stone")
	await _leave_physics_frame()
