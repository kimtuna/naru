extends GutTest
## G-003 2단계 — 게임 씬에 캐릭터 · 카메라가 따라감 · 8방향 이동(대각선 속력 = 직선 속력) · 속력 값은 한 곳.

const KEYS := {
	InputActions.MOVE_UP: KEY_W,
	InputActions.MOVE_DOWN: KEY_S,
	InputActions.MOVE_LEFT: KEY_A,
	InputActions.MOVE_RIGHT: KEY_D,
}
## 8방향 — 누를 액션들과 기대하는 방향.
const DIRECTIONS := [
	[[InputActions.MOVE_UP], Vector2(0, -1)],
	[[InputActions.MOVE_DOWN], Vector2(0, 1)],
	[[InputActions.MOVE_LEFT], Vector2(-1, 0)],
	[[InputActions.MOVE_RIGHT], Vector2(1, 0)],
	[[InputActions.MOVE_UP, InputActions.MOVE_LEFT], Vector2(-1, -1)],
	[[InputActions.MOVE_UP, InputActions.MOVE_RIGHT], Vector2(1, -1)],
	[[InputActions.MOVE_DOWN, InputActions.MOVE_LEFT], Vector2(-1, 1)],
	[[InputActions.MOVE_DOWN, InputActions.MOVE_RIGHT], Vector2(1, 1)],
]
const PLAYER_SCENE := "res://player/player.tscn"

var _held: Array[StringName] = []


func after_each() -> void:
	_release_all()
	Session.clear()


func _key(action: StringName, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEYS[action]
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _press(actions: Array) -> void:
	for a in actions:
		_key(a, true)
		_held.append(a)


func _release_all() -> void:
	for a in _held:
		_key(a, false)
	_held.clear()
	for a in KEYS:
		Input.action_release(a)


func _player() -> Player:
	var p: Player = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child_autofree(p)
	return p


## 입력을 누른 채 실제 물리 루프에서 딱 한 걸음 움직이고, 움직인 거리 / 한 걸음 시간 = 실제 속력 벡터를 돌려준다.
## physics_frame 신호는 매 물리 걸음의 노드 처리 직전에 나오므로, 신호 두 번 사이 = 한 걸음.
func _move_once(p: Player, actions: Array) -> Vector2:
	_press(actions)
	await get_tree().physics_frame
	var before := p.global_position
	await get_tree().physics_frame
	var moved := (p.global_position - before) * Engine.physics_ticks_per_second
	_release_all()
	return moved


# --- 게임 씬에 캐릭터가 있고 카메라가 따라간다 ---

func test_game_scene_has_player_with_current_camera() -> void:
	Session.character = CharacterData.new()
	Session.world = WorldData.create("X", 1)
	var game: GameScene = add_child_autofree((load(Screens.GAME) as PackedScene).instantiate())
	await wait_process_frames(1)
	var p := game.player()
	assert_not_null(p, "game scene has no player")
	assert_true(p is CharacterBody2D)
	assert_true(p.is_visible_in_tree())
	assert_true(p.get_node("Body").is_visible_in_tree(), "player body not visible")
	assert_true(p.camera().enabled)
	assert_eq(get_viewport().get_camera_2d(), p.camera(), "player camera is not the current camera")


func test_camera_follows_player_when_moving() -> void:
	Session.character = CharacterData.new()
	Session.world = WorldData.create("X", 1)
	var game: GameScene = add_child_autofree((load(Screens.GAME) as PackedScene).instantiate())
	var p := game.player()
	var start := p.global_position
	_press([InputActions.MOVE_RIGHT, InputActions.MOVE_DOWN])
	await wait_physics_frames(10)
	_release_all()
	await wait_process_frames(1)
	assert_gt(p.global_position.x, start.x + 1.0, "player did not move right in the real loop")
	assert_gt(p.global_position.y, start.y + 1.0, "player did not move down in the real loop")
	var cam := p.camera()
	cam.force_update_scroll()
	assert_almost_eq(cam.get_screen_center_position(), p.global_position, Vector2(0.01, 0.01),
		"camera center is not on the player")


# --- 8방향 · 대각선 속력 = 직선 속력 ---

func test_all_eight_directions_move_at_same_speed() -> void:
	var p := _player()
	var speed := p.tuning.move_speed
	assert_gt(speed, 0.0)
	for d in DIRECTIONS:
		var moved: Vector2 = await _move_once(p, d[0])
		var want: Vector2 = d[1].normalized()
		assert_almost_eq(moved.length(), speed, 0.01, "speed wrong for %s" % [d[1]])
		assert_almost_eq(moved.normalized().dot(want), 1.0, 0.0001, "direction wrong for %s" % [d[1]])


func test_diagonal_speed_equals_straight_speed() -> void:
	var p := _player()
	var straight: float = (await _move_once(p, [InputActions.MOVE_RIGHT])).length()
	var diagonal: float = (await _move_once(p, [InputActions.MOVE_UP, InputActions.MOVE_RIGHT])).length()
	assert_gt(straight, 0.0)
	assert_almost_eq(diagonal, straight, 0.01, "diagonal must not be faster (%.3f vs %.3f)" % [diagonal, straight])


func test_no_input_no_movement() -> void:
	var p := _player()
	assert_eq(await _move_once(p, []), Vector2.ZERO)


func test_opposite_keys_cancel() -> void:
	var p := _player()
	assert_eq(await _move_once(p, [InputActions.MOVE_LEFT, InputActions.MOVE_RIGHT]), Vector2.ZERO)


# --- 이동 속력 값은 한 곳 ---

func test_default_speed_comes_from_tuning_resource() -> void:
	var p := _player()
	var tuning := MovementTuning.load_default()
	assert_not_null(tuning, "missing " + MovementTuning.DEFAULT_PATH)
	assert_eq(p.tuning, tuning, "player must use the shared tuning resource")
	assert_almost_eq((await _move_once(p, [InputActions.MOVE_UP])).length(), tuning.move_speed, 0.01)


func test_changing_tuning_changes_speed() -> void:
	var p := _player()
	var custom := MovementTuning.new()
	custom.move_speed = 137.0
	p.tuning = custom
	assert_almost_eq((await _move_once(p, [InputActions.MOVE_LEFT])).length(), 137.0, 0.01)
	assert_almost_eq((await _move_once(p, [InputActions.MOVE_DOWN, InputActions.MOVE_LEFT])).length(), 137.0, 0.01)


func test_player_scene_does_not_override_speed() -> void:
	var text := FileAccess.get_file_as_string(PLAYER_SCENE)
	assert_false(text.contains("move_speed"), "speed must live only in the tuning resource")
	assert_false(text.contains("tuning"), "player scene must not set its own tuning")
