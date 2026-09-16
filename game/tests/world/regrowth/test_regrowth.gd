extends GutTest
## G-004 5단계 — 자원 재생. spec/03_world/resources-regrowth.md
## 재생 = 없앤 표시를 지우기: 원래 값으로만 돌아가고, 설치물 둘레 · 플레이어가 선 칸은 비켜날 때까지 기다린다.

const Deposit := IslandConfig.Deposit
const SEED := 4242

var cfg: RegrowthConfig
var map: IslandMap
var view: IslandView
var regrowth: Regrowth


func before_each() -> void:
	cfg = RegrowthConfig.load_default()
	map = IslandMap.new(IslandGenerator.new(SEED), true)
	view = IslandView.new()
	add_child_autofree(view)
	view.setup(map)
	regrowth = Regrowth.new()
	regrowth.config = cfg
	add_child_autofree(regrowth)
	regrowth.setup(map, view, null)


## 스폰 둘레에서 이 자원이 있는 칸들 (skip 제외), 가까운 것부터 n 개.
func _cells(deposit: Deposit, n: int, skip: Array = []) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var s := map.spawn()
	for r in range(1, 80):
		for y in range(s.y - r, s.y + r + 1):
			for x in range(s.x - r, s.x + r + 1):
				var cell := Vector2i(x, y)
				if maxi(absi(x - s.x), absi(y - s.y)) != r or cell in skip or cell in out:
					continue
				if map.has_cell(cell) and map.deposit_at(cell) == deposit:
					out.append(cell)
					if out.size() == n:
						return out
	fail_test("not enough %s" % deposit)
	return out


func _one(deposit: Deposit) -> Vector2i:
	return _cells(deposit, 1)[0]


## 시간을 seconds 흘린다 (check_interval 보다 잘게 쪼개 실제 흐름처럼).
func _elapse(seconds: float) -> void:
	var step := cfg.check_interval * 0.5
	var left := seconds
	while left > 0.0:
		regrowth.advance(minf(step, left))
		left -= step
	regrowth.check()


func _body(at: Vector2) -> Node2D:
	var body := Node2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 12)
	col.shape = shape
	body.add_child(col)
	add_child_autofree(body)
	body.global_position = at
	return body


# --- 원래 값으로만 ---

func test_regrown_cells_match_the_seed_original() -> void:
	var fresh := IslandGenerator.generate(SEED)
	var cells: Array[Vector2i] = []
	cells.append_array(_cells(Deposit.TREE, 5))
	cells.append_array(_cells(Deposit.STONE, 5))
	cells.append_array(_cells(Deposit.ORE, 5))
	for c in cells:
		assert_true(map.remove_deposit(c))
		assert_eq(map.deposit_at(c), Deposit.NONE)
	_elapse(cfg.period_of(Deposit.ORE) + 1.0)
	for c in cells:
		assert_false(map.is_removed(c), "mark cleared at %s" % [c])
		assert_ne(fresh.deposit_at(c), Deposit.NONE)
		assert_eq(map.deposit_at(c), fresh.deposit_at(c), "regrown %s must equal seed value" % [c])
		assert_true(map.is_blocked(c))


func test_regrow_restores_cells_in_chunks_not_built_yet() -> void:
	var full := IslandGenerator.generate(SEED)
	# 스폰에서 먼 덩어리의 나무 — 아직 안 만들었다. (섬 가장자리는 바다라 덩어리 거리로 찾는다)
	var far := Vector2i(-1, -1)
	var home := full.chunk_of(full.spawn())
	for y in full.size:
		for x in full.size:
			var d := (full.chunk_of(Vector2i(x, y)) - home).abs()
			if maxi(d.x, d.y) >= 3 and full.deposit_at(Vector2i(x, y)) == Deposit.TREE:
				far = Vector2i(x, y)
				break
		if far.x >= 0:
			break
	assert_ne(far, Vector2i(-1, -1))
	var marks := {far: true}
	var times := {far: 0.0}
	var lazy := IslandMap.new(IslandGenerator.new(SEED), true, marks, times)
	regrowth.setup(lazy, view, null)
	assert_false(lazy.is_chunk_built(lazy.chunk_of(far)))
	_elapse(cfg.period_of(Deposit.TREE) + 1.0)
	assert_false(marks.has(far), "shared save marks are cleared")
	assert_false(times.has(far))
	assert_eq(lazy.deposit_at(far), Deposit.TREE)


func test_originally_empty_cells_never_grow() -> void:
	var fresh := IslandGenerator.generate(SEED)
	var s := map.spawn()
	var empties: Array[Vector2i] = []
	for y in range(s.y - 30, s.y + 31):
		for x in range(s.x - 30, s.x + 31):
			var c := Vector2i(x, y)
			if fresh.deposit_at(c) == Deposit.NONE:
				empties.append(c)
	assert_gt(empties.size(), 500)
	# 조작된 저장처럼 빈 칸에 없앤 표시가 있어도 재생은 아무것도 만들지 않는다.
	for c in empties:
		map.removed[c] = true
	var harvested := _cells(Deposit.TREE, 10)
	for c in harvested:
		map.remove_deposit(c)
	_elapse(cfg.period_of(Deposit.ORE) * 3.0)
	var count := 0
	var fresh_count := 0
	for y in range(s.y - 30, s.y + 31):
		for x in range(s.x - 30, s.x + 31):
			var c := Vector2i(x, y)
			if map.deposit_at(c) != Deposit.NONE:
				count += 1
			if fresh.deposit_at(c) != Deposit.NONE:
				fresh_count += 1
	for c in empties:
		assert_eq(map.deposit_at(c), Deposit.NONE, "empty %s stays empty" % [c])
	assert_eq(count, fresh_count, "island never gets denser than the seed")
	assert_eq(map.removed.size(), 0)


func test_nothing_regrows_before_its_period() -> void:
	var tree := _one(Deposit.TREE)
	map.remove_deposit(tree)
	_elapse(cfg.period_of(Deposit.TREE) - 5.0)
	assert_eq(map.deposit_at(tree), Deposit.NONE)
	assert_true(map.is_removed(tree))
	_elapse(10.0)
	assert_eq(map.deposit_at(tree), Deposit.TREE)


func test_period_counts_from_when_the_cell_was_emptied() -> void:
	var trees := _cells(Deposit.TREE, 2)
	map.remove_deposit(trees[0])
	_elapse(cfg.period_of(Deposit.TREE) * 0.5)
	map.remove_deposit(trees[1])
	_elapse(cfg.period_of(Deposit.TREE) * 0.5 + 2.0)
	assert_eq(map.deposit_at(trees[0]), Deposit.TREE)
	assert_eq(map.deposit_at(trees[1]), Deposit.NONE, "emptied later, grows later")


func test_regrow_redraws_the_cell() -> void:
	var tree := _one(Deposit.TREE)
	map.remove_deposit(tree)
	var changed := []
	map.cell_changed.connect(func(c): changed.append(c))
	var grown := []
	regrowth.regrown.connect(func(c): grown.append(c))
	_elapse(cfg.period_of(Deposit.TREE) + 1.0)
	assert_eq(changed, [tree])
	assert_eq(grown, [tree])


# --- 설치물 둘레 · 플레이어 ---

func test_no_regrowth_around_structures() -> void:
	var tree := _one(Deposit.TREE)
	var r := cfg.structure_radius
	assert_gt(r, 0)
	map.remove_deposit(tree)
	regrowth.add_structure(tree + Vector2i(r, -r))
	_elapse(cfg.period_of(Deposit.TREE) * 3.0)
	assert_eq(map.deposit_at(tree), Deposit.NONE, "inside the structure radius")
	assert_true(map.is_removed(tree), "still waiting")
	regrowth.remove_structure(tree + Vector2i(r, -r))
	regrowth.add_structure(tree + Vector2i(r + 1, 0))
	_elapse(cfg.check_interval)
	assert_eq(map.deposit_at(tree), Deposit.TREE, "just outside the radius grows")


func test_structure_on_the_cell_itself_blocks_regrowth() -> void:
	var stone := _one(Deposit.STONE)
	map.remove_deposit(stone)
	regrowth.add_structure(stone)
	_elapse(cfg.period_of(Deposit.STONE) * 2.0)
	assert_eq(map.deposit_at(stone), Deposit.NONE)
	regrowth.remove_structure(stone)
	_elapse(cfg.check_interval)
	assert_eq(map.deposit_at(stone), Deposit.STONE)


func test_no_regrowth_where_the_player_stands() -> void:
	var tree := _one(Deposit.TREE)
	map.remove_deposit(tree)
	var body := _body(view.cell_center(tree))
	regrowth.setup(map, view, body)
	_elapse(cfg.period_of(Deposit.TREE) * 2.0)
	assert_eq(map.deposit_at(tree), Deposit.NONE, "player is standing there")
	body.global_position = view.cell_center(tree + Vector2i(3, 0))
	_elapse(cfg.check_interval)
	assert_eq(map.deposit_at(tree), Deposit.TREE, "grows once the player steps off")


func test_player_straddling_cells_blocks_all_of_them() -> void:
	var trees := _cells(Deposit.TREE, 1)
	var a := trees[0]
	var b := a + Vector2i.RIGHT
	map.remove_deposit(a)
	map.remove_deposit(b)
	map.removed[b] = true  # b 가 원래 빈 칸이어도 표시는 남긴다
	# 두 칸 경계 위에 선다.
	var body := _body(Vector2((a.x + 1) * view.tile_px(), view.cell_center(a).y))
	regrowth.setup(map, view, body)
	assert_true(a in regrowth.player_cells())
	assert_true(b in regrowth.player_cells())
	assert_false(a + Vector2i.LEFT in regrowth.player_cells())
	_elapse(cfg.period_of(Deposit.ORE) * 2.0)
	assert_eq(map.deposit_at(a), Deposit.NONE)
	assert_true(map.is_removed(a))
	assert_true(map.is_removed(b))


# --- 주기 ---

func test_periods_order_tree_stone_ore() -> void:
	assert_lt(cfg.period_of(Deposit.TREE), cfg.period_of(Deposit.STONE))
	assert_lt(cfg.period_of(Deposit.STONE), cfg.period_of(Deposit.ORE))
	assert_gt(cfg.period_of(Deposit.TREE), 0.0)
	assert_eq(cfg.period_of(Deposit.NONE), 0.0, "stray marks on empty ground just clear")


func test_regrowth_happens_in_order_tree_then_stone_then_ore() -> void:
	var tree := _one(Deposit.TREE)
	var stone := _one(Deposit.STONE)
	var ore := _one(Deposit.ORE)
	for c in [tree, stone, ore]:
		map.remove_deposit(c)
	var t := cfg.period_of(Deposit.TREE)
	var s := cfg.period_of(Deposit.STONE)
	var o := cfg.period_of(Deposit.ORE)
	_elapse((t + s) / 2.0)
	assert_eq(map.deposit_at(tree), Deposit.TREE)
	assert_eq(map.deposit_at(stone), Deposit.NONE)
	assert_eq(map.deposit_at(ore), Deposit.NONE)
	_elapse((s + o) / 2.0 - (t + s) / 2.0)
	assert_eq(map.deposit_at(stone), Deposit.STONE)
	assert_eq(map.deposit_at(ore), Deposit.NONE)
	_elapse(o - (s + o) / 2.0 + 1.0)
	assert_eq(map.deposit_at(ore), Deposit.ORE)


func test_periods_come_from_the_config() -> void:
	# 값은 regrowth_config 한 곳에서만 온다 — 바꾸면 동작이 따라 바뀐다.
	var custom := RegrowthConfig.new()
	custom.day_seconds = 10.0
	custom.tree_days = 1.0
	custom.stone_days = 2.0
	custom.ore_days = 3.0
	custom.check_interval = 0.5
	assert_eq(custom.period_of(Deposit.STONE), 20.0)
	regrowth.config = custom
	cfg = custom
	var stone := _one(Deposit.STONE)
	map.remove_deposit(stone)
	_elapse(19.0)
	assert_eq(map.deposit_at(stone), Deposit.NONE)
	_elapse(1.5)
	assert_eq(map.deposit_at(stone), Deposit.STONE)
	var node := Regrowth.new()
	add_child_autofree(node)
	assert_eq(node.config.resource_path, RegrowthConfig.DEFAULT_PATH, "default config is the single source")
