extends TestBase

## 손을 잰다 — **순수 계산과 화면 자리의 기하**. 픽셀에 정말 그려졌는지와
## 숫자키가 정말 손을 옮기는지는 `measure_window.gd` 의 HOTBAR 가 잰다.
##
## **숫자를 글자로 박는다** (바퀴 19 의 교훈): 9칸도 화면 아래도 사람이 정한 값이라
## `Hotbar.SLOTS` 라는 **이름**으로만 쓰면 8칸으로 줄여도 한 줄이 안 빨개진다.

const WOOD := &"wood"
const STONE := &"stone"
const SCREEN := Vector2(960.0, 540.0)   # 논리 화면 (NUMBERS 1절)

func test_hotbar_is_nine_slots_the_human_chose() -> void:
	# 숫자키 1..9 한 줄이다. **0 은 안 쓴다** — 10번째 칸이 생기면 키가 줄 끝에서 끊긴다.
	eq(Hotbar.SLOTS, 9, "핫바 칸 수")
	var h := Hotbar.new()
	eq(h.slot_count(), 9, "실제로 만들어진 칸 수")
	# **가방과 다른 9칸이다.** 같은 객체를 보면 핫바에 넣은 것이 가방 칸을 먹는다.
	eq(Inventory.SLOTS, 18, "가방 칸 수 (핫바와 따로다)")
	check(h.items.slot_count() != Inventory.SLOTS,
		"핫바는 가방과 다른 칸이어야 한다 — 잰 값 %d · 가방 %d" % [h.items.slot_count(), Inventory.SLOTS])

func test_hand_starts_on_the_first_slot() -> void:
	var h := Hotbar.new()
	eq(h.selected, 0, "처음 손에 든 칸")
	check(h.is_empty_handed(), "빈 핫바로 시작하면 맨손이어야 한다")
	eq(h.held_id(), Hotbar.EMPTY, "맨손의 아이디")
	eq(h.held_amount(), 0, "맨손의 개수")

func test_number_keys_pick_the_slot() -> void:
	var h := Hotbar.new()
	# 화면의 1번 칸이 키 1 이다 — 사람이 세는 수와 칸 번호가 하나씩 어긋난다.
	for n in range(1, 10):
		eq(h.select_by_number(n), n - 1, "숫자 %d 를 누르면 드는 칸" % n)
		eq(h.selected, n - 1, "숫자 %d 뒤의 손" % n)

func test_out_of_range_does_not_move_the_hand() -> void:
	# 엉뚱한 값에 손이 조용히 옮겨 가면, 다음 좌클릭이 딴짓을 하는데
	# 사람은 무엇을 눌렀는지 모른다. **감싸지도 자르지도 않는다.**
	var h := Hotbar.new()
	h.select(4)
	for bad in [-1, -100, 9, 10, 999]:
		eq(h.select(bad), 4, "범위 밖 %d 를 골라도 손이 그대로여야 한다" % bad)
		eq(h.selected, 4, "범위 밖 %d 뒤의 손" % bad)
	# 숫자키 0 은 없다. 키 10 도 없다.
	eq(h.select_by_number(0), 4, "숫자 0 은 칸이 아니다")
	eq(h.select_by_number(10), 4, "숫자 10 은 칸이 아니다")

func test_hand_shows_what_is_in_the_selected_slot() -> void:
	var h := Hotbar.new()
	eq(h.items.add(WOOD, 12), 0, "핫바에 목재 12개를 넣으면 남는 것이 없어야 한다")
	eq(h.items.add(STONE, 5), 0, "핫바에 돌 5개를 넣으면 남는 것이 없어야 한다")
	h.select(0)
	eq(h.held_id(), WOOD, "0번 칸을 들면 손의 아이디")
	eq(h.held_amount(), 12, "0번 칸을 들면 손의 개수")
	check(not h.is_empty_handed(), "물건이 든 칸을 들면 맨손이 아니다")
	h.select(1)
	eq(h.held_id(), STONE, "1번 칸을 들면 손의 아이디")
	eq(h.held_amount(), 5, "1번 칸을 들면 손의 개수")

func test_empty_slot_is_an_empty_hand() -> void:
	# **빈 칸을 고를 수 있어야 한다.** 못 고르게 막으면 맨손으로 돌아갈 길이 없다.
	var h := Hotbar.new()
	h.items.add(WOOD, 3)
	h.select(8)
	eq(h.selected, 8, "빈 8번 칸을 들 수 있어야 한다")
	check(h.is_empty_handed(), "빈 칸을 들면 맨손이다")
	eq(h.held_amount(), 0, "맨손의 개수")

func test_hotbar_slot_holds_the_same_stack_as_the_bag() -> void:
	# 한 칸 999 (바퀴 19 · 사람이 정했다). 손과 가방이 다른 상한을 쓰면
	# 가방에서 손으로 옮기는 순간 개수가 사라진다.
	var h := Hotbar.new()
	eq(h.items.add(WOOD, 999), 0, "한 칸에 999개가 들어가야 한다")
	eq(h.items.amounts[0], 999, "첫 칸의 개수")
	eq(h.items.free_slots(), 8, "999개까지는 한 칸만 쓴다")
	eq(h.items.add(WOOD, 1), 0, "1000번째는 둘째 칸을 연다")
	eq(h.items.free_slots(), 7, "1000번째 뒤의 빈 칸")
	# 핫바 한 줄의 용량. 가방(17,982)과 다른 수다 — 칸 수가 다르기 때문이다.
	var full := Hotbar.new()
	for i in Hotbar.SLOTS:
		full.items.add(StringName("item_%d" % i), 999)
	eq(full.items.total(), 8991, "핫바 한 줄 용량 (9칸 × 999)")

func test_actions_and_slots_round_trip() -> void:
	# 액션 이름은 **한 곳에서** 나온다. project.godot 의 글자와 갈라지면
	# 키를 눌러도 아무 일이 안 일어나는데 단위 검사는 전부 초록이다.
	for i in Hotbar.SLOTS:
		eq(Hotbar.action_for(i), StringName("hotbar_%d" % (i + 1)), "칸 %d 의 액션 이름" % i)
		eq(Hotbar.index_for_action(Hotbar.action_for(i)), i, "액션 → 칸 %d" % i)
	eq(Hotbar.action_for(0), &"hotbar_1", "첫 칸은 hotbar_1 이다")
	eq(Hotbar.action_for(8), &"hotbar_9", "마지막 칸은 hotbar_9 이다")
	for bad in [&"move_left", &"hotbar_0", &"hotbar_10", &"hotbar_", &"hotbar_x", &"", &"otbar_1"]:
		eq(Hotbar.index_for_action(bad), -1, "핫바 액션이 아닌 %s" % bad)

func test_bar_sits_at_the_bottom_of_the_screen() -> void:
	# **「화면 아래 상시」가 이 검사다** (GDD D-2c). 자리를 앵커가 아니라 함수로 낸 이유다.
	var bar := HotbarView.bar_rect(SCREEN)
	check(bar.position.x >= 0.0 and bar.end.x <= SCREEN.x,
		"핫바가 화면 가로 안에 있어야 한다 — 잰 값 %.1f .. %.1f · 화면 %.0f" % [bar.position.x, bar.end.x, SCREEN.x])
	check(bar.end.y <= SCREEN.y,
		"핫바가 화면 아래로 안 넘쳐야 한다 — 잰 값 %.1f · 화면 %.0f" % [bar.end.y, SCREEN.y])
	# 아래 절반이 아니라 **바닥에 붙어** 있어야 한다. 8px 띄운 값이다.
	eq(SCREEN.y - bar.end.y, 8.0, "핫바 아래 여백 (px)")
	# 가로 가운데. 양쪽 여백이 같다.
	eq(bar.position.x, SCREEN.x - bar.end.x, "핫바 좌우 여백이 같아야 한다")
	# 9칸 × 32 + 8틈 × 2 = 304 x 32. 숫자로 박는다 — 칸이 커지면 여기가 빨개진다.
	eq(bar.size, Vector2(304.0, 32.0), "핫바 줄 크기")
	eq(bar.position, Vector2(328.0, 500.0), "핫바 줄 자리 (960x540 화면)")
	# 화면을 얼마나 먹나. 1/6 을 넘으면 보이는 월드를 갉아먹는다.
	var share := bar.get_area() / (SCREEN.x * SCREEN.y)
	check(share < 1.0 / 6.0, "핫바가 화면의 %.1f%% 를 먹는다 · 기대 16.7%% 미만" % (share * 100.0))

func test_nine_slot_rects_tile_the_bar_without_overlap() -> void:
	var bar := HotbarView.bar_rect(SCREEN)
	var prev := Rect2()
	for i in Hotbar.SLOTS:
		var r := HotbarView.slot_rect(i, SCREEN)
		eq(r.size, Vector2(32.0, 32.0), "칸 %d 크기 (2 타일)" % i)
		check(bar.encloses(r), "칸 %d 가 줄 안에 있어야 한다 — 잰 값 %s · 줄 %s" % [i, r, bar])
		if i > 0:
			eq(r.position.x - prev.end.x, 2.0, "칸 %d 와 %d 사이 틈 (px)" % [i - 1, i])
			check(not r.intersects(prev), "칸 %d 와 %d 가 겹치면 안 된다" % [i - 1, i])
		prev = r
	# 양 끝이 줄의 양 끝이다 — 9칸이 줄을 남김없이 채운다.
	eq(HotbarView.slot_rect(0, SCREEN).position.x, bar.position.x, "첫 칸의 왼쪽 = 줄의 왼쪽")
	eq(HotbarView.slot_rect(Hotbar.SLOTS - 1, SCREEN).end.x, bar.end.x, "마지막 칸의 오른쪽 = 줄의 오른쪽")

func test_held_slot_is_drawn_differently() -> void:
	# 손에 든 칸이 다른 색이 아니면 **9칸이 늘 똑같이 보인다** — 숫자키를 눌러도
	# 화면이 안 변한다. 픽셀로 확인하는 것은 measure_window 의 HOTBAR 다.
	check(HotbarView.EDGE_HELD != HotbarView.EDGE,
		"손에 든 칸의 테두리는 다른 색이어야 한다 — 잰 값 %s" % HotbarView.EDGE.to_html(false))
	check(HotbarView.BG.a == 1.0 and HotbarView.EDGE.a == 1.0 and HotbarView.EDGE_HELD.a == 1.0,
		"핫바는 불투명해야 한다 (뒤의 월드가 비치면 픽셀로 못 잰다)")
	# 아이템 네모는 **테두리 안쪽 바탕을 남긴다** — 실측 게이트가 볼 점이 거기다.
	check(HotbarView.SWATCH_INSET > HotbarView.BORDER,
		"아이템 네모는 테두리보다 안쪽이어야 한다 — 잰 값 %.1f · 테두리 %.1f" % [
			HotbarView.SWATCH_INSET, HotbarView.BORDER])

func test_item_colors_are_stable_and_tell_items_apart() -> void:
	# 자리표시자지만 **결정적이어야 한다** — 프레임마다 색이 바뀌면 눈이 못 읽는다.
	eq(HotbarView.item_color(WOOD), HotbarView.item_color(WOOD), "같은 아이디는 같은 색")
	check(HotbarView.item_color(WOOD) != HotbarView.item_color(STONE),
		"다른 아이디는 다른 색이어야 한다")
