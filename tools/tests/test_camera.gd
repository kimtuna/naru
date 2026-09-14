extends TestBase

## 카메라에 **씬으로 박혀 있는 값**을 잰다 (P1-6).
##
## **줌이 곧 시야다**: 1 이 아니면 창이 큰 사람이 더 멀리 본다 (BACKLOG P1 「줌 없음」).
## 부드럽게 따라가는 것(position_smoothing)도 여기서 끈다 — 끌려오는 화면은
## 「같은 입력 = 같은 화면」이 아니고, 프레임률에 따라 뒤처지는 양이 달라진다.
##
## 여기가 잡는 것은 **글자**다. 실행 중에 코드가 줌을 만지거나 카메라를 꺼 버리면
## 이 파일은 전부 초록으로 남는다 — 그건 `tools/tests/measure_camera.gd` 가 잡는다.

const PLAYER := "res://scenes/player.tscn"
const MAIN := "res://scenes/main.tscn"

func test_camera_rides_the_player() -> void:
	# **코드가 매 프레임 따라 붙이지 않는다.** 플레이어의 자식이라 공짜로 따라간다 —
	# 따라 붙이는 코드는 물리와 그리기 사이에 한 틱 뒤처질 자리를 만든다.
	var p: Node = load(PLAYER).instantiate()
	var cam := p.get_node_or_null("Camera") as Camera2D
	if cam == null:
		failures.append("플레이어 씬에 Camera2D 'Camera' 가 있어야 한다")
	else:
		# 원점은 **발밑**이다 (회차 16) — 카메라가 비추는 것도 그 점이다.
		eq(cam.position, Vector2.ZERO, "카메라가 플레이어 원점(발밑)에 있어야 한다")
	p.free()

func test_camera_zoom_is_one() -> void:
	# 줌 = 시야. 2배로 당기면 보이는 칸이 20 → 10 이 된다 (NUMBERS 1절 대조군).
	var p: Node = load(PLAYER).instantiate()
	var cam := p.get_node_or_null("Camera") as Camera2D
	if cam == null:
		failures.append("플레이어 씬에 Camera2D 'Camera' 가 있어야 한다")
	else:
		eq(cam.zoom, Vector2.ONE, "카메라 줌")
	p.free()

func test_camera_does_not_lag_or_drag() -> void:
	var p: Node = load(PLAYER).instantiate()
	var cam := p.get_node_or_null("Camera") as Camera2D
	if cam == null:
		failures.append("플레이어 씬에 Camera2D 'Camera' 가 있어야 한다")
		p.free()
		return
	check(not cam.position_smoothing_enabled, "위치 부드럽게 따라가기는 꺼야 한다 (화면이 끌린다)")
	check(not cam.rotation_smoothing_enabled, "회전 부드럽게 따라가기는 꺼야 한다")
	check(not cam.drag_horizontal_enabled, "가로 드래그 여백은 꺼야 한다")
	check(not cam.drag_vertical_enabled, "세로 드래그 여백은 꺼야 한다")
	eq(cam.offset, Vector2.ZERO, "카메라 오프셋")
	eq(cam.anchor_mode, Camera2D.ANCHOR_MODE_DRAG_CENTER, "앵커 모드(플레이어가 화면 중앙)")
	p.free()

func test_camera_limits_do_not_cut_the_world() -> void:
	# 한계가 월드 안쪽에 걸리면 가장자리에서 카메라가 멈춰 플레이어가 중앙을 벗어난다.
	var p: Node = load(PLAYER).instantiate()
	var cam := p.get_node_or_null("Camera") as Camera2D
	if cam == null:
		failures.append("플레이어 씬에 Camera2D 'Camera' 가 있어야 한다")
		p.free()
		return
	var edge := int(WorldGen.SIZE * PlayerMotion.TILE)
	check(cam.limit_left <= 0, "왼쪽 한계 — 잰 값 %d · 기대 0 이하" % cam.limit_left)
	check(cam.limit_top <= 0, "위쪽 한계 — 잰 값 %d · 기대 0 이하" % cam.limit_top)
	check(cam.limit_right >= edge, "오른쪽 한계 — 잰 값 %d · 기대 %d 이상" % [cam.limit_right, edge])
	check(cam.limit_bottom >= edge, "아래쪽 한계 — 잰 값 %d · 기대 %d 이상" % [cam.limit_bottom, edge])
	p.free()

func test_main_scene_has_exactly_one_camera() -> void:
	# 둘이면 **누가 화면을 잡는지 노드 순서가 정한다** — 먼저 들어온 쪽이 이긴다.
	var m: Node = load(MAIN).instantiate()
	var found: Array[String] = []
	_collect(m, m, found)
	eq(found.size(), 1, "메인 씬의 카메라 수 (찾은 것 %s)" % str(found))
	m.free()

func _collect(root: Node, n: Node, out: Array[String]) -> void:
	if n is Camera2D:
		out.append(str(root.get_path_to(n)))
	for c in n.get_children():
		_collect(root, c, out)
