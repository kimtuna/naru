extends "res://tests/life/harvest/harvest_test_base.gd"
## G-006 제작대 테스트가 함께 쓰는 준비 — 게임에 들어가 제작대를 들고 좌클릭한다.
## 파일 이름이 test_ 로 시작하지 않아 혼자서는 돌지 않는다.

const WORKBENCH := "workbench"


func _bench(count := 1) -> Dictionary:
	return {"id": WORKBENCH, "count": count}


## 손에 든 칸 (_hold 가 고르는 3번 칸)의 아이템.
func _held(game: GameScene) -> Variant:
	return game.player().held_item()


## 실제 좌클릭 입력으로 이 칸을 한 번 누르고 뗀다.
func _click_cell(game: GameScene, cell: Vector2i) -> void:
	var screen_mid := get_viewport().get_visible_rect().size / 2.0
	Pointer.simulate(game.island_view().cell_center(cell))
	_click(true, screen_mid)
	await wait_physics_frames(2)
	_click(false, screen_mid)
	await wait_physics_frames(1)


func _press_action(action: StringName) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		Input.flush_buffered_events()


## 스폰에 서서 오른쪽 빈 칸에 제작대를 놓는다.
func _place_next_to_spawn(game: GameScene) -> Vector2i:
	var here := game.island.spawn()
	_stand(game, here)
	_hold(game, _bench())
	var cell := here + Vector2i.RIGHT
	await _click_cell(game, cell)
	assert_not_null(game.stations().station_at(cell), "setup: workbench was not placed")
	return cell
