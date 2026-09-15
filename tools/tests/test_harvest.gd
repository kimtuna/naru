extends TestBase

## 벌목의 **판정**을 잰다 — 무엇으로 무엇을 베나 · 어느 칸을 치나 · 무엇이 떨어지나.
## 게임이 이걸 정말 부르는지는 `measure_chop.gd` 의 CHOP 이 메인 씬을 돌려서 잰다.
##
## **숫자와 글자를 박는다** (회차 19 의 교훈): 「도끼로 나무를 벤다」를 `Harvest.AXE`
## 라는 이름으로만 쓰면 아이디를 통째로 바꿔도 한 줄이 안 빨개진다.

const SEED := 20260914
const NOT_A_TOOL := &"wood"        # 손에 들 수는 있지만 나무를 베지는 못하는 것

## ── 도구가 판정을 가른다 ─────────────────────────────────────────────

func test_the_names_are_the_ones_that_were_chosen() -> void:
	eq(Harvest.AXE, &"axe", "도끼의 아이디")
	eq(Harvest.WOOD, &"wood", "목재의 아이디")
	eq(Harvest.tool_for(WorldObjects.TREE), &"axe", "나무를 베는 도구")
	eq(Harvest.drop_for(WorldObjects.TREE), &"wood", "나무에서 떨어지는 것")
	eq(Harvest.drop_amount(WorldObjects.TREE), 3, "나무 한 그루에서 나오는 개수")

## **맨손으로는 나무를 못 벤다.** 빈 손이 「아무 도구나」가 되면 도구가 의미를 잃는다 —
## 그런데 맨손도 **휘두르기는 한다** (HandSwing 머리말). 모션과 판정은 따로다.
func test_only_the_axe_fells_a_tree() -> void:
	check(Harvest.can_harvest(&"axe", WorldObjects.TREE), "도끼로 나무를 벨 수 있어야 한다")
	check(not Harvest.can_harvest(Inventory.EMPTY, WorldObjects.TREE), "맨손으로는 못 벤다")
	check(not Harvest.can_harvest(NOT_A_TOOL, WorldObjects.TREE),
		"목재를 들고는 못 벤다 — 잰 값 %s" % Harvest.tool_for(WorldObjects.TREE))
	# 빈 칸은 무엇을 들어도 안 거둬진다. 「빈 땅을 치면 아무 일도 없다」가 그 문장이다.
	check(not Harvest.can_harvest(&"axe", WorldObjects.NONE), "빈 칸은 도끼로도 못 벤다")

## **돌·광물은 도끼로 안 캐진다** — 채광은 곡괭이의 것이고 아직 없다 (BACKLOG P2).
## 「아직 도구가 없다」와 「아무 도구나 된다」는 다르다.
func test_rock_and_ore_are_not_the_axes_work() -> void:
	for kind in [WorldObjects.ROCK, WorldObjects.ORE]:
		eq(Harvest.tool_for(kind), Inventory.EMPTY, "종류 %d 를 캐는 도구" % kind)
		eq(Harvest.drop_amount(kind), 0, "종류 %d 에서 나오는 개수" % kind)
		check(not Harvest.can_harvest(&"axe", kind), "도끼로 종류 %d 를 캘 수 없어야 한다" % kind)

## ── 어느 칸을 치나 ───────────────────────────────────────────────────

## **겨눈 쪽으로 한 칸.** 네 방향 전부 본다 — 한 축의 부호만 틀려도
## 「위를 보는데 아래가 베인다」가 되는데, 사람은 그걸 「가끔 안 맞는다」로 겪는다.
func test_the_target_is_one_tile_toward_the_facing() -> void:
	var here := Vector2i(100, 100)
	var pos := PlayerMotion.tile_center(here.x, here.y)
	eq(Harvest.standing_tile(pos), here, "서 있는 칸")
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		eq(Harvest.target_tile(pos, Vector2(d)), here + d, "%s 를 볼 때 치는 칸" % d)

## **칸 한가운데가 아니어도 같은 칸이다.** 칸 안 어디에 서 있든 치는 칸은 안 바뀐다 —
## 걸으면서 클릭하면 판정이 반 칸마다 흔들리면 안 된다.
func test_the_target_does_not_wobble_inside_a_tile() -> void:
	var here := Vector2i(100, 100)
	var corner := Vector2(here.x * PlayerMotion.TILE, here.y * PlayerMotion.TILE)
	var offs: Array[Vector2] = [Vector2(0.5, 0.5), Vector2(15.5, 15.5), Vector2(8.0, 1.0), Vector2(1.0, 8.0)]
	for off in offs:
		var pos := corner + off
		eq(Harvest.target_tile(pos, Vector2.RIGHT), here + Vector2i(1, 0),
			"칸 안 %s 에서 오른쪽을 칠 때" % off)

## **대각선으로 겨눠도 칸은 상하좌우 하나다** — 방향은 4방향이다 (PlayerFacing).
func test_a_diagonal_aim_still_picks_one_axis() -> void:
	var pos := PlayerMotion.tile_center(0, 0)
	eq(Harvest.target_tile(pos, Vector2(3.0, 1.0)), Vector2i(1, 0), "오른쪽에 가까운 대각선")
	eq(Harvest.target_tile(pos, Vector2(1.0, 3.0)), Vector2i(0, 1), "아래쪽에 가까운 대각선")
	# 방향이 0 이어도 칸 하나는 나온다 — 판정이 예외로 죽으면 클릭이 통째로 씹힌다.
	eq(Harvest.target_tile(pos, Vector2.ZERO), Vector2i(1, 0), "방향이 없을 때")

## **사거리와 한 칸이 맞아떨어진다.** REACH 24px = 8(내 칸의 반) + 16(옆 칸) 이라
## 손이 옆 칸의 **먼 모서리**에 딱 닿는다 — 그래서 「치는 칸 = 한 칸」이 그림과 같다.
## 이 등식이 깨지면 휘두르는 네모가 안 닿는 칸이 베이거나, 닿는 칸이 안 베인다.
func test_the_reach_is_exactly_one_tile_away() -> void:
	eq(HandSwing.REACH, PlayerMotion.TILE * 0.5 + PlayerMotion.TILE,
		"사거리 = 내 칸의 반 + 옆 칸 (px)")
	check(HandSwing.REACH < PlayerMotion.TILE * 0.5 + PlayerMotion.TILE * 2.0,
		"사거리가 두 칸 건너의 먼 모서리(40px)에 닿으면 안 된다 — 잰 값 %.1f" % HandSwing.REACH)

## ── 한 번 휘두른 것을 월드에 먹인다 ──────────────────────────────────

func test_a_swing_with_an_axe_fells_the_tree_in_front() -> void:
	var w := WorldState.new(SEED)
	var tree := _a_tree(w)
	if tree == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	# 나무의 **왼쪽 칸**에 서서 오른쪽을 본다.
	var pos := PlayerMotion.tile_center(tree.x - 1, tree.y)
	eq(Harvest.hit(w, &"axe", pos, Vector2.RIGHT), WorldObjects.TREE, "도끼로 친 결과")
	eq(w.object_at(tree.x, tree.y), WorldObjects.NONE, "벤 뒤 그 칸에 남은 것")
	eq(w.cleared_count(), 1, "없어진 칸의 수")
	# **목재가 바닥에 떨어진다** — 가방이 아니라 바닥이다 (Harvest 머리말).
	eq(w.drop_count(), 1, "바닥에 떨어진 더미의 수")
	eq(w.dropped_total(&"wood"), 3, "바닥에 떨어진 목재")
	eq(w.drops[0]["pos"], PlayerMotion.tile_center(tree.x, tree.y), "떨어진 자리")
	# **벤 자리로 걸어 들어갈 수 있다.** 이게 안 되면 「베었다」가 거짓말이다.
	check(not w.solid().call(tree.x, tree.y), "벤 칸이 아직도 막는다")

## **한 번 벤 나무를 또 베도 목재가 또 나오지 않는다.** 누르고 있으면 계속 휘두르므로
## (HandSwing) 같은 칸에 모션이 몇 번이고 더 간다 — 여기가 새면 목재가 무한히 나온다.
func test_felling_the_same_tile_twice_drops_nothing_more() -> void:
	var w := WorldState.new(SEED)
	var tree := _a_tree(w)
	if tree == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	var pos := PlayerMotion.tile_center(tree.x - 1, tree.y)
	Harvest.hit(w, &"axe", pos, Vector2.RIGHT)
	eq(Harvest.hit(w, &"axe", pos, Vector2.RIGHT), WorldObjects.NONE, "두 번째로 친 결과")
	eq(w.dropped_total(&"wood"), 3, "두 번 친 뒤 바닥의 목재")
	eq(w.cleared_count(), 1, "두 번 친 뒤 없어진 칸의 수")

## **맨손·엉뚱한 도구로는 월드가 한 톨도 안 바뀐다.**
func test_the_wrong_hand_changes_nothing() -> void:
	var w := WorldState.new(SEED)
	var tree := _a_tree(w)
	if tree == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	var pos := PlayerMotion.tile_center(tree.x - 1, tree.y)
	for held in [Inventory.EMPTY, NOT_A_TOOL, &"pickaxe"]:
		eq(Harvest.hit(w, held, pos, Vector2.RIGHT), WorldObjects.NONE, "%s 로 친 결과" % held)
	eq(w.object_at(tree.x, tree.y), WorldObjects.TREE, "나무는 그대로여야 한다")
	eq(w.cleared_count(), 0, "없어진 칸의 수")
	eq(w.drop_count(), 0, "바닥에 떨어진 것의 수")

## **엉뚱한 쪽을 보고 치면 나무가 안 베인다.** 판정이 방향을 정말 쓰는지 묻는다 —
## 「닿는 칸이면 아무거나」로 짜면 등 뒤의 나무가 베인다.
func test_facing_away_misses_the_tree() -> void:
	var w := WorldState.new(SEED)
	var tree := _a_tree(w)
	if tree == Vector2i.MAX:
		check(false, "씨앗 %d 에서 나무를 하나도 못 찾았다" % SEED)
		return
	var pos := PlayerMotion.tile_center(tree.x - 1, tree.y)
	eq(Harvest.hit(w, &"axe", pos, Vector2.LEFT), WorldObjects.NONE, "등지고 친 결과")
	eq(w.object_at(tree.x, tree.y), WorldObjects.TREE, "나무는 그대로여야 한다")

## 씨앗에서 **왼쪽 칸이 비어 있는** 나무를 하나 찾는다. 못 찾으면 `Vector2i.MAX`.
## 스폰 둘레부터 훑는다 — 사람이 처음 만나는 나무가 그쪽이다.
func _a_tree(w: WorldState) -> Vector2i:
	var sp := WorldGen.spawn_tile()
	for r in range(WorldObjects.SPAWN_CLEAR + 1, 40):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var t := Vector2i(sp.x + dx, sp.y + dy)
				if w.object_at(t.x, t.y) == WorldObjects.TREE \
						and w.object_at(t.x - 1, t.y) == WorldObjects.NONE:
					return t
	return Vector2i.MAX
