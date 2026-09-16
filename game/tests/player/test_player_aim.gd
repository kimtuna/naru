extends GutTest
## G-003 3단계 — 바라보는 방향은 Pointer 쪽이고 이동 방향과 상관없다.

const PLAYER_SCENE := "res://player/player.tscn"
const KEYS := {
	InputActions.MOVE_UP: KEY_W,
	InputActions.MOVE_DOWN: KEY_S,
	InputActions.MOVE_LEFT: KEY_A,
	InputActions.MOVE_RIGHT: KEY_D,
}

var _saved_reader: Callable
var _real_calls := 0


func before_each() -> void:
	_saved_reader = Pointer.real_reader
	_real_calls = 0
	Pointer.real_reader = _spy_reader
	Pointer.clear_simulation()


func after_each() -> void:
	for a in KEYS:
		_key(a, false)
		Input.action_release(a)
	Pointer.real_reader = _saved_reader
	Pointer.clear_simulation()


func _spy_reader(_it: CanvasItem) -> Vector2:
	_real_calls += 1
	return Vector2(-9999, -9999)


func _key(action: StringName, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEYS[action]
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _player() -> Player:
	var p: Player = (load(PLAYER_SCENE) as PackedScene).instantiate()
	add_child_autofree(p)
	return p


## 한 물리 걸음 — physics_frame 신호는 노드 처리 직전에 나오므로, 그 직후 커서를 캐릭터 기준 offset 에 두면
## 이번 걸음에서 캐릭터가 읽는 커서는 정확히 그 자리다. 걸음이 끝날 때까지 기다린다.
func _aim_and_step(p: Player, offset: Vector2) -> void:
	await get_tree().physics_frame
	Pointer.simulate(p.global_position + offset)
	await get_tree().process_frame


func _assert_dir(got: Vector2, want: Vector2, msg: String) -> void:
	assert_almost_eq(got.length(), 1.0, 0.0001, msg + " (facing must be a unit vector)")
	assert_almost_eq(got.dot(want.normalized()), 1.0, 0.0001, "%s: got %s want %s" % [msg, got, want])


# --- 왼쪽으로 가면서 오른쪽을 본다 ---

func test_moving_left_while_facing_right_pointer() -> void:
	var p := _player()
	p.facing = Vector2.LEFT  # 시작 값에 기대지 않게 반대로 둔다
	_key(InputActions.MOVE_LEFT, true)
	var xs: Array[float] = []
	for i in 10:
		xs.append(p.global_position.x)
		await _aim_and_step(p, Vector2(50, 0))
		_assert_dir(p.facing, Vector2.RIGHT, "frame %d while walking left" % i)
		assert_almost_eq(p.get_node("%Aim").rotation, 0.0, 0.0001, "aim marker must point right")
	assert_lt(p.global_position.x, xs[0] - 1.0, "player must actually be walking left")
	assert_lt(p.velocity.x, 0.0, "velocity must point left")
	assert_eq(_real_calls, 0, "player must read the cursor through Pointer only")


func test_facing_ignores_every_move_direction() -> void:
	var p := _player()
	var target := Vector2(0, -70)  # 위쪽을 겨눈다
	for dir in [[InputActions.MOVE_DOWN], [InputActions.MOVE_RIGHT], [InputActions.MOVE_DOWN, InputActions.MOVE_LEFT]]:
		for a in dir:
			_key(a, true)
		for i in 3:
			await _aim_and_step(p, target)
		assert_ne(p.velocity, Vector2.ZERO, "player must be moving for %s" % [dir])
		assert_true(p.velocity.dot(target) <= 0.0, "moving %s is not toward the pointer" % [dir])
		_assert_dir(p.facing, Vector2.UP, "moving %s" % [dir])
		for a in dir:
			_key(a, false)


# --- 바라보는 방향은 Pointer 를 따라간다 ---

func test_facing_follows_pointer_in_any_direction() -> void:
	var p := _player()
	for want in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(3, -4), Vector2(-2, 5)]:
		Pointer.simulate(p.global_position + want * 30.0)
		await wait_physics_frames(1)
		_assert_dir(p.facing, want, "pointer at %s" % [want])
		assert_almost_eq(p.get_node("%Aim").rotation, want.angle(), 0.0001)


func test_pointer_is_relative_to_player_world_position() -> void:
	var p := _player()
	p.global_position = Vector2(500, 500)
	# 월드 원점 기준으로는 오른쪽 아래지만, 캐릭터 기준으로는 왼쪽 위다.
	Pointer.simulate(Vector2(400, 400))
	await wait_physics_frames(1)
	_assert_dir(p.facing, Vector2(-1, -1), "pointer up-left of player")


func test_pointer_on_player_keeps_last_facing() -> void:
	var p := _player()
	Pointer.simulate(p.global_position + Vector2(0, 40))
	await wait_physics_frames(1)
	_assert_dir(p.facing, Vector2.DOWN, "setup")
	Pointer.simulate(p.global_position)
	await wait_physics_frames(1)
	_assert_dir(p.facing, Vector2.DOWN, "pointer exactly on player")
