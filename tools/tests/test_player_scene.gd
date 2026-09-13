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
	var body := p.get_node_or_null("Body") as ColorRect
	if body == null:
		failures.append("색 네모(ColorRect 'Body')가 있어야 한다")
	else:
		# 캐릭터 키 = 타일 1칸 (NUMBERS 1절). 중심이 노드 원점에 오게 반 칸씩 밀려 있다.
		eq(body.size, Vector2(48, 48), "색 네모 크기")
		eq(body.position, Vector2(-24, -24), "색 네모 오프셋(중심 맞춤)")
	p.free()

func test_player_uses_the_motion_class() -> void:
	# 노드가 제 속도를 따로 들고 있으면 NUMBERS 의 값이 두 곳에 생긴다.
	var src := FileAccess.get_file_as_string("res://scripts/player.gd")
	check(src.contains("PlayerMotion."), "player.gd 는 PlayerMotion 을 써야 한다")
	check(not src.contains("240"), "속도 숫자를 player.gd 에 다시 적으면 안 된다 (출처는 PlayerMotion)")

func test_main_scene_places_player_on_a_tile_center() -> void:
	var m: Node = load(MAIN).instantiate()
	var p := m.get_node_or_null("Player") as Node2D
	if p == null:
		failures.append("메인 씬에 Player 가 있어야 한다")
		m.free()
		return
	var t := PlayerMotion.TILE
	eq(Vector2(fmod(p.position.x, t), fmod(p.position.y, t)), Vector2(t * 0.5, t * 0.5),
		"플레이어 시작 위치가 타일 중심이어야 한다 (잰 값 %s)" % p.position)
	# 카메라가 아직 없다 (P1-6). 시작할 때 화면 안에 있어야 보인다.
	var vw: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vh: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	check(Rect2(0, 0, vw, vh).has_point(p.position), "시작 위치가 화면 안 — 잰 값 %s" % p.position)
	m.free()
