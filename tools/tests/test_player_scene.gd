extends TestBase

## 씬과 입력 배선을 잰다. 계산이 맞아도 배선이 끊기면 게임은 안 움직인다.

const PLAYER := "res://scenes/player.tscn"
const MAIN := "res://scenes/main.tscn"

# WASD — 물리 키코드다. 자판 배열이 달라도 같은 자리다 (GDD D-2c).
const KEYS := {"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W, "move_down": KEY_S}

func test_input_actions_are_wasd() -> void:
	for action in KEYS:
		if not InputMap.has_action(action):
			failures.append("입력 액션이 없다: %s" % action)
			continue
		var found := false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and e.physical_keycode == KEYS[action]:
				found = true
		check(found, "%s 가 물리 키 %s 에 묶여야 한다" % [action, OS.get_keycode_string(KEYS[action])])

func test_player_scene_is_a_colored_square() -> void:
	check(ResourceLoader.exists(PLAYER), "플레이어 씬이 있어야 한다: %s" % PLAYER)
	var p: Node = load(PLAYER).instantiate()
	check(p is CharacterBody2D, "루트는 CharacterBody2D 여야 한다 — 잰 값 %s" % p.get_class())
	var t := PlayerMotion.TILE
	var body := p.get_node_or_null("Body") as ColorRect
	if body == null:
		failures.append("색 네모(ColorRect 'Body')가 있어야 한다")
	else:
		# 몸통은 **1칸 폭 × 1.5칸 키** 다 (BACKLOG 고정값 · 코어 키퍼 비율).
		# **원점이 발밑**이라(바퀴 16) 네모는 그 위로 선다: 아래끝이 발밑 상자의 아래끝과 같다.
		eq(body.size, Vector2(t, t * 1.5), "색 네모 크기 (1칸 폭 × 1.5칸 키)")
		eq(body.position, Vector2(-t * 0.5, WorldCollide.HALF.y - t * 1.5),
			"색 네모 오프셋 (가로 가운데 · 아래끝 = 발밑 상자 아래끝)")
		# **셋으로 갈라져 있던 값이 여기서 만난다.** 몸통이 1칸보다 넓으면 벽에 붙었을 때
		# 그만큼이 막힌 칸에 파묻혀 보인다 — 48px 이던 때가 한쪽에 10px 였다.
		check(body.size.x <= t, "몸통 폭 — 잰 값 %.2f px · 기대 1칸(%.2f px) 이하" % [body.size.x, t])
	# **충돌 상자는 발밑 반 칸이다.** 씬의 모양은 지금 아무도 안 읽지만
	# (`move_and_slide` 를 안 쓴다 — WorldCollide 머리말) 값이 갈라지면 나중에 물리를
	# 붙이는 사람이 **다른 몸**을 얻는다. 그래서 WorldCollide 에 묶어 둔다.
	var shape := p.get_node_or_null("Shape") as CollisionShape2D
	var rect: RectangleShape2D = null
	if shape != null:
		rect = shape.shape as RectangleShape2D
	if rect == null:
		failures.append("충돌 상자(CollisionShape2D 'Shape' + RectangleShape2D)가 있어야 한다")
	else:
		eq(rect.size, WorldCollide.HALF * 2.0, "충돌 상자 크기 (발밑 반 칸)")
		eq(shape.position, Vector2.ZERO, "충돌 상자 자리 (원점이 곧 발밑이다)")
	p.free()

func test_player_uses_the_motion_class() -> void:
	# 노드가 제 속도를 따로 들고 있으면 NUMBERS 의 값이 두 곳에 생긴다.
	var src := FileAccess.get_file_as_string("res://scripts/player.gd")
	check(src.contains("PlayerMotion."), "player.gd 는 PlayerMotion 을 써야 한다")
	check(not src.contains("240"), "속도 숫자를 player.gd 에 다시 적으면 안 된다 (출처는 PlayerMotion)")

func test_main_scene_places_player_on_the_spawn_tile() -> void:
	var m: Node = load(MAIN).instantiate()
	var p := m.get_node_or_null("Player") as Node2D
	if p == null:
		failures.append("메인 씬에 Player 가 있어야 한다")
		m.free()
		return
	var t := PlayerMotion.TILE
	eq(Vector2(fmod(p.position.x, t), fmod(p.position.y, t)), Vector2(t * 0.5, t * 0.5),
		"플레이어 시작 위치가 타일 중심이어야 한다 (잰 값 %s)" % p.position)
	# **카메라가 생겼으므로**(P1-6) 화면 안일 필요가 없다 — 화면이 플레이어를 따라온다.
	# 대신 섬의 스폰 칸에 정확히 서야 한다. 바퀴 7 의 `tile_offset` 이 사라진 자리다.
	var spawn := WorldGen.spawn_tile()
	eq(p.position, PlayerMotion.tile_center(spawn.x, spawn.y),
		"플레이어 시작 위치 = 스폰 칸 %s 의 중심" % spawn)
	m.free()
