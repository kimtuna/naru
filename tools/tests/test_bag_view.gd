extends TestBase

## 가방 화면을 잰다 — **순수 계산과 자리의 기하**. 픽셀에 정말 그려졌는지와
## `E` 가 정말 열고 닫는지는 `measure_window.gd` 의 BAG 가 잰다.
##
## **숫자를 글자로 박는다** (회차 19·20 의 교훈): 18칸도 9열도 사람이 정한 값이라
## `Inventory.SLOTS` 라는 **이름**으로만 쓰면 12칸으로 줄여도 한 줄이 안 빨개진다.

const SCREEN := Vector2(960.0, 540.0)   # 논리 화면 (NUMBERS 1절)

func test_bag_shows_all_eighteen_slots() -> void:
	# 가방은 18칸이다 (회차 19 · 사람이 정했다). 화면이 그보다 적게 보여주면
	# **넣은 것이 어디로 갔는지 알 길이 없다** — 「넘치는 몫이 사라지지 않는다」가
	# 계산에서만 참이고 사람 눈에는 거짓이 된다.
	eq(Inventory.SLOTS, 18, "가방 칸 수")
	eq(BagView.COLS * BagView.ROWS, 18, "화면이 보여주는 칸 수 (열 × 줄)")
	eq(BagView.COLS, 9, "열 수 — 핫바 9칸과 같아야 위아래가 줄을 맞춘다")
	eq(BagView.ROWS, 2, "줄 수")

func test_columns_line_up_with_the_hotbar() -> void:
	# **위아래가 한 줄에 선다.** 다음 항목(「칸 사이로 아이템을 옮긴다」)이
	# 가방 ↔ 핫바를 오가는데, 열이 어긋나 있으면 어느 칸으로 가는지 눈으로 못 읽는다.
	for c in 9:
		var bag := BagView.slot_rect(c, SCREEN)
		var hot := HotbarView.slot_rect(c, SCREEN)
		eq(bag.position.x, hot.position.x, "%d번 열의 x — 가방과 핫바가 같아야 한다" % (c + 1))
		eq(bag.size, hot.size, "%d번 열의 칸 크기" % (c + 1))
	# 아랫줄도 같은 x 에 선다.
	eq(BagView.slot_rect(9, SCREEN).position.x, HotbarView.slot_rect(0, SCREEN).position.x,
		"아랫줄 첫 칸의 x")

func test_bag_sits_above_the_hotbar_and_hides_neither() -> void:
	var panel := BagView.panel_rect(SCREEN)
	var bar := HotbarView.bar_rect(SCREEN)
	# **핫바를 가리지 않는다** — 「무엇을 들었나」를 보면서 가방을 정리해야 한다.
	check(panel.end.y <= bar.position.y,
		"가방 창 아래끝(%.1f)이 핫바 윗변(%.1f) 위에 있어야 한다" % [panel.end.y, bar.position.y])
	# 붙어 있어야 한 덩어리로 읽힌다. 8px 띄운다 — 화면 반대편에 두면 눈이 오간다.
	check(bar.position.y - panel.end.y <= 16.0,
		"가방과 핫바 사이 틈 — 잰 값 %.1f px · 기대 16 px 이하" % (bar.position.y - panel.end.y))
	# **화면 안이다.** 위로 넘치면 윗줄이 잘려서 칸이 안 보인다.
	check(panel.position.y >= 0.0 and panel.position.x >= 0.0 and panel.end.x <= SCREEN.x,
		"가방 창이 화면 안에 있어야 한다 — 잰 값 %s · 화면 %s" % [panel, SCREEN])
	# 가로 가운데다 (핫바와 같은 규칙).
	eq(panel.position.x + panel.size.x * 0.5, SCREEN.x * 0.5, "가방 창의 가로 중심")

func test_slots_are_inside_the_panel_and_never_overlap() -> void:
	var panel := BagView.panel_rect(SCREEN)
	var rects: Array[Rect2] = []
	for i in 18:
		var r := BagView.slot_rect(i, SCREEN)
		check(panel.encloses(r), "%d번 칸이 창 안에 있어야 한다 — 칸 %s · 창 %s" % [i + 1, r, panel])
		rects.append(r)
	for a in 18:
		for b in a:
			# **테두리끼리도 안 겹친다** — 겹치면 게이트의 탐침이 어느 칸을 읽는지 모호해진다.
			check(not rects[a].intersects(rects[b]),
				"%d번과 %d번 칸이 겹친다 — %s · %s" % [a + 1, b + 1, rects[a], rects[b]])

func test_slot_zero_is_top_left_and_rows_go_down() -> void:
	# 0번이 왼쪽 위다. `Inventory.add` 가 앞 칸부터 채우므로, 처음 주운 것이
	# 화면 왼쪽 위에 나타나야 사람이 「거기 들어갔다」를 본다.
	var s0 := BagView.slot_rect(0, SCREEN)
	var s8 := BagView.slot_rect(8, SCREEN)
	var s9 := BagView.slot_rect(9, SCREEN)
	check(s0.position.x < s8.position.x, "0번이 8번보다 왼쪽이어야 한다")
	eq(s0.position.y, s8.position.y, "0번과 8번은 같은 줄")
	check(s9.position.y > s0.position.y, "9번은 다음 줄이어야 한다")
	eq(s9.position.x, s0.position.x, "9번은 첫 열")
	eq(s9.position.y - s0.position.y, 34.0, "줄 간격 (칸 32 + 틈 2)")

func test_bag_starts_closed_and_e_toggles_it() -> void:
	# **`visible` 이 곧 상태다.** 따로 bool 을 들면 「열렸다는데 안 보인다」가 생긴다.
	var v := BagView.new()
	v.visible = false
	check(not v.is_open(), "처음엔 닫혀 있어야 한다")
	check(v.toggle(), "한 번 누르면 열린다")
	check(v.is_open() and v.visible, "연 뒤 — is_open 과 visible 이 같아야 한다")
	check(not v.toggle(), "같은 키를 또 누르면 닫힌다")
	check(not v.is_open() and not v.visible, "닫은 뒤")
	v.free()

func test_bag_slot_looks_the_same_as_a_hotbar_slot() -> void:
	# 칸의 크기·틈은 **핫바에서 온다**. 같은 물건이 창마다 다른 크기로 보이면
	# 옮기는 동안 무엇이 무엇인지 헷갈린다.
	eq(BagView.SLOT, HotbarView.SLOT, "칸 크기")
	eq(BagView.GAP, HotbarView.GAP, "칸 사이 틈")
	eq(BagView.SLOT, 32.0, "칸 크기 (타일 2칸)")

func test_panel_is_opaque() -> void:
	# **반투명이면 뒤의 월드 색이 섞여서** 「가방이 떴나」를 픽셀로 못 묻는다.
	# 칸 바탕과 테두리도 같은 이유로 불투명하다 (핫바에서 그대로 온다).
	eq(BagView.PANEL.a, 1.0, "창 바탕의 알파")
	eq(HotbarView.BG.a, 1.0, "칸 바탕의 알파")
	eq(HotbarView.EDGE.a, 1.0, "칸 테두리의 알파")
	# 창 바탕과 칸 바탕은 **달라야** 창의 가장자리가 보인다.
	check(BagView.PANEL != HotbarView.BG, "창 바탕과 칸 바탕이 같으면 격자가 안 읽힌다")

func test_geometry_follows_the_screen() -> void:
	# 자리는 **화면 크기의 함수**다. 앵커가 아니라 순수 함수라서 창이 바뀌어도
	# 게이트가 같은 함수로 같은 자리를 찾는다.
	var big := Vector2(1280.0, 720.0)
	var p1 := BagView.panel_rect(SCREEN)
	var p2 := BagView.panel_rect(big)
	eq(p1.size, p2.size, "창 크기가 달라도 가방 창의 크기는 같다 (칸이 상수라서)")
	check(p2.position != p1.position, "화면이 커지면 가방 창의 자리는 따라 옮겨야 한다")
	eq(p2.end.y, HotbarView.bar_rect(big).position.y - BagView.LIFT,
		"큰 화면에서도 핫바 바로 위다")
