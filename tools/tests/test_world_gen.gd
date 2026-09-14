extends TestBase

## 월드 생성을 잰다. 값의 출처는 NUMBERS 6절.
##
## **여기는 한 프로세스 안의 순수 계산만 본다.** 「같은 씨앗 = 같은 월드」의 진짜 주장은
## **다른 프로세스에서도** 같다는 것이고, 그건 tools/tests/measure_world.gd 가 잰다 —
## 정적 변수에 시간을 한 번 섞어 두면 이 파일은 전부 초록으로 남는다.

const SEEDS := [1, 42, -20260914]

func test_size_and_two_kinds() -> void:
	eq(WorldGen.SIZE, 256, "월드 한 변")
	var grid := WorldGen.generate(1)
	eq(grid.size(), 256 * 256, "타일 개수")
	var kinds := {}
	for v in grid:
		kinds[v] = true
	var names := kinds.keys()
	names.sort()
	eq(names, [WorldGen.WATER, WorldGen.LAND], "지형 종류 — 물과 땅 둘뿐이어야 한다")

func test_same_seed_is_same_world() -> void:
	var a := WorldGen.generate(20260914)
	var b := WorldGen.generate(20260914)
	eq(WorldGen.checksum(a), WorldGen.checksum(b), "같은 씨앗 체크섬")
	var diff := 0
	for i in a.size():
		if a[i] != b[i]:
			diff += 1
	eq(diff, 0, "같은 씨앗인데 다른 타일 수")

func test_different_seed_is_different_world() -> void:
	# 전수 생성은 느리다. 32칸 간격 격자만 비교해도 「같은 월드」는 여기서 걸린다.
	for pair in [[1, 2], [42, 43], [-7, 7]]:
		var diff := 0
		var n := 0
		for y in range(0, WorldGen.SIZE, 8):
			for x in range(0, WorldGen.SIZE, 8):
				n += 1
				if WorldGen.tile_at(pair[0], x, y) != WorldGen.tile_at(pair[1], x, y):
					diff += 1
		var pct := 100.0 * diff / n
		check(pct > 2.0, "씨앗 %d 과 %d 의 차이 — 잰 값 %.2f%% · 기대 2%% 초과" % [pair[0], pair[1], pct])

func test_border_is_always_water() -> void:
	# 수학이 보장한다: 감쇠 1.25 > 잡음 최대 1.0. 섬이 화면 밖으로 새면 여기서 터진다.
	for s in SEEDS:
		var wet := true
		var where := ""
		for i in WorldGen.SIZE:
			for p in [Vector2i(i, 0), Vector2i(i, WorldGen.SIZE - 1),
					Vector2i(0, i), Vector2i(WorldGen.SIZE - 1, i)]:
				if WorldGen.tile_at(s, p.x, p.y) != WorldGen.WATER:
					wet = false
					where = str(p)
		check(wet, "씨앗 %d 테두리 — 잰 값 %s 가 땅 · 기대 전부 물" % [s, where])

func test_spawn_is_always_land() -> void:
	# 한가운데가 물이면 플레이어가 바다에 뜬 채로 시작한다 (다음 항목: 이동 충돌).
	var sp := WorldGen.spawn_tile()
	eq(sp, Vector2i(128, 128), "스폰 칸")
	for s in SEEDS + [0, 7, 999983]:
		eq(WorldGen.tile_at(s, sp.x, sp.y), WorldGen.LAND, "씨앗 %d 스폰 지형" % s)

func test_land_ratio_is_an_island() -> void:
	# 12개 씨앗 실측 28.00% ~ 40.97% (NUMBERS 6절). 바닥/천장은 넉넉히 둔다 —
	# 「전부 땅」·「전부 물」·「감쇠 없음」을 잡는 게 목적이지 값을 못 박는 게 아니다.
	for s in [1, 42]:
		var grid := WorldGen.generate(s)
		var pct := 100.0 * WorldGen.land_count(grid) / grid.size()
		check(pct > 18.0 and pct < 55.0,
			"씨앗 %d 땅 비율 — 잰 값 %.2f%% · 기대 18%% ~ 55%%" % [s, pct])

func test_tile_query_matches_the_whole_map() -> void:
	# **순서에 의존하지 않는다**는 주장이다 — 한 장을 통째로 만들든 한 칸만 묻든 같은 답.
	# RandomNumberGenerator 로 짰다면 여기서 터진다.
	var grid := WorldGen.generate(7)
	var bad := 0
	var first := ""
	for y in range(0, WorldGen.SIZE, 7):
		for x in range(0, WorldGen.SIZE, 5):
			var one := WorldGen.tile_at(7, x, y)
			if one != WorldGen.at(grid, x, y):
				bad += 1
				if first == "":
					first = "(%d,%d) 한 칸 %d · 전체 %d" % [x, y, one, WorldGen.at(grid, x, y)]
	eq(bad, 0, "한 칸 질의와 전체 생성이 어긋난 칸 %s" % first)

func test_outside_the_world_is_water() -> void:
	var grid := WorldGen.generate(1)
	for p in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(256, 128), Vector2i(128, 256),
			Vector2i(-999, -999), Vector2i(9999, 9999)]:
		eq(WorldGen.tile_at(1, p.x, p.y), WorldGen.WATER, "월드 밖 %s 한 칸 질의" % p)
		eq(WorldGen.at(grid, p.x, p.y), WorldGen.WATER, "월드 밖 %s 전체 조회" % p)

func test_checksum_notices_one_tile() -> void:
	# 체크섬이 헐거우면 measure_world.gd 의 프로세스 간 비교가 아무것도 안 잡는다.
	var grid := WorldGen.generate(1)
	var before := WorldGen.checksum(grid)
	grid[12345] = 1 - grid[12345]
	check(WorldGen.checksum(grid) != before,
		"타일 하나를 뒤집었는데 체크섬이 그대로다 — 잰 값 0x%08x" % before)
