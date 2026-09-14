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
		# 몸통은 **1칸 폭 × 2칸 키** 다 (회차 17 · BACKLOG 고정값 — 키 32px = 타일 2칸).
		# **원점이 발밑**이라(회차 16) 네모는 그 위로 선다: 아래끝이 발밑 상자의 아래끝과 같다.
		eq(body.size, Vector2(t, t * 2.0), "색 네모 크기 (1칸 폭 × 2칸 키)")
		eq(body.position, Vector2(-t * 0.5, WorldCollide.HALF.y - t * 2.0),
			"색 네모 오프셋 (가로 가운데 · 아래끝 = 발밑 상자 아래끝)")
		# **셋으로 갈라져 있던 값이 여기서 만난다.** 몸통이 1칸보다 넓으면 벽에 붙었을 때
		# 그만큼이 막힌 칸에 파묻혀 보인다 — 1.5칸이던 회차 15 까지가 한쪽에 10px 였다.
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
	# 대신 섬의 스폰 칸에 정확히 서야 한다. 회차 7 의 `tile_offset` 이 사라진 자리다.
	var spawn := WorldGen.spawn_tile()
	eq(p.position, PlayerMotion.tile_center(spawn.x, spawn.y),
		"플레이어 시작 위치 = 스폰 칸 %s 의 중심" % spawn)
	m.free()

func test_number_keys_are_bound_to_the_hotbar() -> void:
	# 숫자키 1..9 (GDD D-2c). **물리 키코드다** — WASD 와 같은 이유로 자판 배열을 안 탄다.
	# 액션 이름은 `Hotbar.action_for` 가 만든다: 여기서 글자를 다시 적으면
	# 「배선은 맞는데 코드가 다른 이름을 부른다」를 못 잡는다.
	for i in Hotbar.SLOTS:
		var action := Hotbar.action_for(i)
		if not InputMap.has_action(action):
			failures.append("입력 액션이 없다: %s" % action)
			continue
		var want := KEY_1 + i
		var found := false
		for e in InputMap.action_get_events(action):
			if e is InputEventKey and e.physical_keycode == want:
				found = true
		check(found, "%s 가 물리 키 %s 에 묶여야 한다" % [action, OS.get_keycode_string(want)])
	# 10번째 키는 없다 — 핫바가 9칸이기 때문이다.
	check(not InputMap.has_action(&"hotbar_10"), "hotbar_10 은 있으면 안 된다 (9칸이다)")

func test_main_scene_has_the_hotbar_on_a_canvas_layer() -> void:
	# **카메라를 타면 안 된다.** Node2D 밑에 그냥 달면 걸을 때 핫바가 같이 흘러간다 —
	# 픽셀로는 measure_window 의 HOTBAR 가 잡지만, 배선은 여기서 막는다.
	var m: Node = load(MAIN).instantiate()
	var layer := m.get_node_or_null("UI") as CanvasLayer
	if layer == null:
		failures.append("메인 씬에 CanvasLayer 'UI' 가 있어야 한다")
		m.free()
		return
	var view := layer.get_node_or_null("Hotbar")
	if view == null or not (view is HotbarView):
		failures.append("UI 밑에 HotbarView 'Hotbar' 가 있어야 한다 — 잰 값 %s" % view)
	m.free()

func test_left_click_is_bound_to_use() -> void:
	# **좌클릭 하나다** (GDD D-2c). 액션 이름은 `main.gd` 의 상수가 출처다 —
	# 여기서 글자를 다시 적으면 「배선은 맞는데 코드가 다른 이름을 부른다」를 못 잡는다.
	var action: StringName = load("res://scripts/main.gd").get_script_constant_map()["USE_ACTION"]
	eq(action, &"use", "좌클릭 액션 이름")
	if not InputMap.has_action(action):
		failures.append("입력 액션이 없다: %s" % action)
		return
	var found := false
	for e in InputMap.action_get_events(action):
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			found = true
	check(found, "%s 가 **마우스 왼쪽 버튼**에 묶여야 한다" % action)

func test_player_scene_has_the_swing_rect() -> void:
	var p: Node = load(PLAYER).instantiate()
	var tool_rect := p.get_node_or_null("Tool") as ColorRect
	if tool_rect == null:
		failures.append("휘두르는 네모(ColorRect 'Tool')가 있어야 한다")
		p.free()
		return
	eq(tool_rect.size, HandSwing.SIZE, "휘두르는 네모 크기 (반 칸)")
	# **안 휘두를 때는 안 보인다.** 늘 떠 있으면 모션이 아니라 장식이다 —
	# 씬에 켜 둔 채로 두면 첫 프레임부터 화면에 네모가 하나 더 있다.
	check(not tool_rect.visible, "휘두르는 네모는 씬에서 꺼져 있어야 한다")
	# 도구가 몸통보다 크면 손에 쥔 것으로 안 보인다.
	var body := p.get_node_or_null("Body") as ColorRect
	if body != null:
		check(tool_rect.size.x < body.size.x and tool_rect.size.y < body.size.y,
			"휘두르는 네모는 몸통보다 작아야 한다 — 잰 값 %s · 몸통 %s" % [tool_rect.size, body.size])
	p.free()

func test_a_swing_starts_with_no_world_and_no_target() -> void:
	# **대상이 없어도 사용 모션이 나온다** (BACKLOG P2). 여기 플레이어는 월드가 안 꽂혀
	# 있고(`solid` 가 빈 Callable) 맞힐 것도 하나 없다 — 그래도 모션은 돌아야 한다.
	# 픽셀로 다시 보는 것은 measure_window 의 USE 다.
	var p: Player = load(PLAYER).instantiate()
	# **`_ready` 를 손으로 부른다**: 헤드리스 러너는 프레임을 한 번도 안 돌려서
	# `root` 가 아직 트리 밖이다 — 트리에 붙여도 `@onready` 가 안 채워진다 (GOTCHAS).
	p.notification(Node.NOTIFICATION_READY)
	var tool_rect := p.get_node_or_null("Tool") as ColorRect
	check(p.solid.is_null(), "월드가 안 꽂힌 플레이어여야 한다 (대상이 하나도 없는 상태)")
	check(not p.swing.is_swinging(), "좌클릭 전에는 안 휘두른다")
	check(tool_rect != null and not tool_rect.visible, "좌클릭 전에는 네모가 안 보인다")
	check(p.use(HandSwing.BARE), "대상이 없어도 좌클릭이 모션을 시작해야 한다")
	check(p.swing.is_swinging(), "시작한 뒤에는 휘두르는 중이다")
	if tool_rect != null:
		check(tool_rect.visible, "휘두르는 동안 네모가 보여야 한다")
		# 네모가 **몸통 한가운데에서 사거리만큼** 떨어져 있다. 자리가 계산과 갈라지면
		# 화면에는 나오는데 엉뚱한 데서 휘두른다.
		var body := p.get_node_or_null("Body") as ColorRect
		var center: Vector2 = body.position + body.size * 0.5
		var d: float = center.distance_to(tool_rect.position + tool_rect.size * 0.5)
		check(absf(d - HandSwing.REACH) < 0.01,
			"몸통 한가운데 → 네모 중심 거리 — 잰 값 %.3f px · 기대 %.1f px" % [d, HandSwing.REACH])
	# **겹쳐 눌러도 한 모션이다.**
	check(not p.use(HandSwing.BARE), "휘두르는 중에 또 누르면 새 모션이 시작되면 안 된다")
	# 모션이 끝나면 네모가 사라진다 — 게임에서는 `_process` 가 시간을 넣어 준다.
	p.swing.advance(HandSwing.SWING_SEC)
	p._place_tool()
	check(not p.swing.is_swinging(), "0.24초가 지나면 모션이 끝난다")
	if tool_rect != null:
		check(not tool_rect.visible, "모션이 끝나면 네모가 사라져야 한다")
	p.free()
