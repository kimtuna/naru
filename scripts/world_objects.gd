class_name WorldObjects
extends RefCounted

## 땅 위에 놓이는 것들의 **순수 배치** — 나무 · 돌 · 광물 1종 (GDD E-7 「자원」).
## `WorldGen` 과 같은 규칙을 지킨다: 노드도 엔진 상태도 전역 RNG 도 안 본다.
## **좌표를 넣으면 답이 나오는 해시**라 순서가 없다 — 한 칸만 물어도 한 장을 통째로
## 구워도 같은 답이고, 프로세스가 달라도 같다 (GDD D-1 서버 재현성).
##
## **지형을 바꾸지 않는다.** 나무가 선 칸도 지형은 여전히 땅이다 — 베면 도로 풀밭이라야
## 하고(A-4 「한 번 캐고 끝나는 자원이 없다」), 그리는 쪽·막는 쪽이 지형과 오브젝트를
## 따로 물을 수 있어야 한다. 그래서 `WorldGen` 의 두 종류는 그대로 둔다.
##
## ── 세 종류를 **한 번의 추첨**으로 가른다 ────────────────────────────
## 칸마다 0..1 값을 하나 뽑아 구간으로 나눈다. 종류마다 따로 뽑으면 한 칸에 둘이
## 겹치고, 「누가 이기나」라는 규칙이 또 필요해진다 — 구간이면 겹칠 수가 없다.
##
## ── 나무는 **뭉친다**, 흩뿌려지지 않는다 ────────────────────────────
## 칸마다 독립으로 뽑으면 온 섬에 고르게 깔린 점이 된다: 어디를 가도 똑같아서
## 「저 숲으로 가자」가 없다. 그래서 **낮은 주파수 잡음이 그 칸의 나무 확률을 정한다** —
## 지형과 같은 `WorldGen.value` 를 쓰되 씨앗을 어긋낸다(안 그러면 숲이 해안선을 베낀다).
## `FOREST_FLOOR` 아래는 확률이 0 이라 **빈터가 생긴다** — 숲과 빈터가 갈려야 지도가 읽힌다.
##
## ── 광물은 **섬 안쪽 높은 땅에만** ──────────────────────────────────
## 통화가 광물 본위라(GDD C-5) 아무 데나 있으면 안 된다. 높이 문턱을 하나 걸면
## 해안에는 없고 안쪽에만 있다 — 「산에 간다」가 저절로 생긴다 (GDD D-4).
##
## ── 얼마나 놓이나: **손잡이는 둘뿐이다** (회차 38) ──────────────────
## 회차 37 까지는 종류마다 제 문턱이 따로 있었다 — `TREE_MAX 0.42` · `ROCK_RATE 0.020`
## · `ORE_RATE 0.006`. 셋이 서로를 모르므로 **하나를 만지면 나머지 둘과의 비가 같이
## 흔들린다**: 「숲을 좀 늘리자」가 「광물이 상대적으로 귀해졌다」를 말없이 같이 했다.
## 균형을 느끼는 단위는 밀도가 아니라 **비**다(나무 몇 그루에 광물 하나냐) —
## 안 흔들려야 하는 쪽이 조용히 흔들리던 자리다.
##
## 이제 묻는 것은 둘이다:
##   `FILL` — **땅의 몇 할**이 무언가로 채워지나 (지도가 얼마나 빽빽한가)
##   `MIX`  — 그 몫을 종류끼리 **어떻게 나누나** (무엇이 귀한가)
## 종류별 확률은 아래에서 **나눗셈으로 나온다.** 종류마다 따로 만질 수 있는 상수는
## 하나도 안 남는다 — 그것이 이 절의 주장 전부다.

const NONE := 0
const TREE := 1
const ROCK := 2
const ORE := 3

## 배치용 해시 소금. **지형과 같은 씨앗을 그대로 쓰면 안 된다** — 잡음이 겹쳐
## 나무가 높이의 무늬를 베낀다 (WorldView.TINT_SALT 와 같은 이유).
const PLACE_SALT := 0x2f6a88d1
const FOREST_SALT := 0x7e13c5a9

## 숲 잡음. 월드 한 변에 이만큼 들어간다 — 1칸 ≈ 18타일이라 한 화면(60칸)에
## 숲과 빈터가 서너 번 갈린다.
const FOREST_CELLS := 14.0
const FOREST_FLOOR := 0.42     # 이 아래는 나무가 하나도 없다 (빈터)

const ORE_MIN_HEIGHT := 0.55   # 이 높이 위에만 광물 (해수면 0.30 · 최대 1.00)

## 땅 칸의 몇 할이 무언가로 채워지나. **빽빽함 하나만 정한다** — 무엇이 채우는지는
## 안 정한다. 11.6% 는 회차 37 까지의 세 문턱이 실제로 만들던 값이다(NUMBERS 6b):
## 손잡이를 바꾸는 회차와 균형을 바꾸는 회차를 갈라 놓으려고 그대로 뒀다.
const FILL := 0.116

## 그 몫을 종류끼리 나누는 **비**. 여기 있는 것은 비율이라 **합이 몇이든 상관없다** —
## 셋을 전부 두 배로 적어도 섬은 한 글자도 안 변한다. 변하는 것은 서로의 크기뿐이다.
##
## 36 : 8 : 1 은 **회차 37 까지의 섬을 재서 옮겨 적은 값이다**(36.72 : 7.57 : 1).
## `REGROW_DAYS` 의 1·3·7 과 같은 **자리표시자**이고, 값이 아니라 **순서가 규칙이다**:
## 나무 > 돌 > 광물. 광물이 통화 본위라(GDD C-5) 가장 귀해야 하고, 돌은 건축 자재라
## 그 사이다. 검사는 값과 순서를 따로 묻는다.
##
## **백로그가 예로 든 3 : 2 : 1 은 여기 안 넣었다.** 그대로 넣으면 광물이 땅의 1.9% 가
## 되어 지금의 **6배**다 — 통화가 돌만큼 흔해진다. 비를 얼마로 할지는 값의 문제가
## 아니라 **경제의 문제라 사람이 정한다.** 이 회차가 판 것은 「어디서 정하나」다.
const MIX := {
	TREE: 36.0,
	ROCK: 8.0,
	ORE: 1.0,
}

## ── 나눗셈에 `REACH` 가 끼는 이유 ────────────────────────────────────
## `MIX` 는 「**땅 전체**에서 차지할 몫」인데, 종류마다 놓일 수 있는 땅이 다르다:
## 돌은 아무 땅에나, 광물은 `ORE_MIN_HEIGHT` 위에만, 나무는 숲 잡음이 센 데만.
## 뽑을 확률을 몫과 같게 두면 **좁은 데만 놓이는 것이 그만큼 적게 나온다** —
## 좁을수록 그 안에서 진하게 뽑아야 섬 전체의 몫이 맞는다.
##
## 그래서 등식은 하나다: **밀도 = 뽑을 확률 × REACH**. `REACH` 는 그 종류에게
## 열려 있는 땅의 몫이고 — 돌 1.0(전부) · 광물 0.4470(높은 땅) ·
## 나무 0.2201(숲 잡음의 평균 세기) — **잰 값이다** (NUMBERS 6b, 씨앗 8개 전수).
##
## **씨앗 평균이지 한 섬의 값이 아니다.** 높은 땅은 씨앗마다 9.99% ~ 69.46% 로
## **7배**가 흔들리고 광물도 그대로 7배 흔들린다. 그건 고칠 것이 아니라 값이다 —
## 섬마다 광맥의 빈부가 갈려야 「이 섬은 나무 섬이다」가 생긴다.
##
## **세어서 맞추지 않는다.** 「지금 몇 개인지 세고 모자란 만큼 채운다」는 한 장을
## 통째로 봐야 답이 나오는 계산이라, 한 칸만 물어도 답이 나오는 해시가 깨진다
## (GDD D-1 재현성). 재생에도 안 쓴다 — 재생은 시드의 원래 값으로 돌아가는 것이라
## 비가 저절로 지켜진다.
##
## **이 값들은 지형이 바뀌면 낡는다.** `ORE_MIN_HEIGHT` 나 `FOREST_FLOOR` 를 만지면
## 여기도 다시 재야 한다 — `test_reach_still_matches_the_land` 가 그때 빨개진다.
const REACH := {
	TREE: 0.2201,
	ROCK: 1.0,
	ORE: 0.4470,
}

## 종류별로 한 칸에서 뽑을 확률. **`FILL` 과 `MIX` 와 `REACH` 말고는 아무것도 안 본다** —
## 여기에 종류 이름이 붙은 상수가 하나라도 더 끼면 손잡이가 셋으로 도로 갈라진다.
##
## 한 번만 셈하고 갖고 있는다: `at_height` 가 칸마다 세 번 부르는 자리다
## (전수 한 장 = 65,536칸 × 3). **시간도 순서도 안 섞인다** — 상수만 보고 만든
## 표라서 프로세스가 달라도 같은 값이다 (회차 6 · 24 가 막은 구멍과 다른 종류다).
static var _rate: Dictionary = {}

static func rate(kind: int) -> float:
	if _rate.is_empty():
		var total := 0.0
		for k in MIX:
			total += MIX[k]
		for k in MIX:
			_rate[k] = FILL * MIX[k] / total / REACH[k]
	return _rate.get(kind, 0.0)

## 스폰 칸에서 이만큼(체비쇼프)은 **반드시 비운다** — 7 x 7 빈터다.
##
## 두 가지를 보장한다: ① 플레이어가 나무 속에 갇힌 채 시작하지 않는다
## ② 어느 방향으로도 세 칸은 걸어 나갈 수 있다. ②가 없으면 스폰 둘레의 운에 따라
## 「시작하자마자 못 움직이는 씨앗」이 생기고, 그건 검사가 아니라 사람이 겪는다.
const SPAWN_CLEAR := 3

## ── 다시 자란다 (GDD A-4 「한 번 캐고 끝나는 자원이 없다」) ──────────
## **날 수로 적는다, 초가 아니다.** 하루가 몇 초인지는 시계의 것이고(`WorldState.DAY_SEC`),
## 여기 있는 것은 「나무 한 그루는 하루」라는 **균형값**이다 — 하루 길이를 고치는 회차가
## 이 파일을 안 열어도 된다.
##
## **셋 다 자란다. 속도가 다를 뿐이다** (회차 37). 회차 30 은 돌·광물을 0(안 자람)으로
## 두고 「캔 자리에 도로 생기면 광산과 자동화(A-4)가 의미를 잃는다」를 근거로 댔는데,
## **그건 틀렸다**: 광산이 파는 것은 **공급이 아니라 노동**이다 (GDD D-7). 나무 공장도
## 나무가 없어서가 아니라 **베러 다니기 싫어서** 선다 — 야생 나무는 계속 자라는데도.
## 안 자라게 두면 반대쪽이 터진다: 초반에 야생 철을 다 캔 판은 **광산 방을 지을 재료도
## 없이 막힌다.** 안 자라는 자원은 A-4 가 금지하는 「한 번 캐고 끝나는 것」 그 자체다.
##
## **광물이 가장 느리다** — 통화가 광물 본위라(GDD C-5) 흔해지면 경제가 흔들리고,
## 그 느림이 **광산 방을 지을 동기**다. 돌은 그 사이다: 건축 자재라 수요는 크지만
## 값을 매기지 않는다.
##
## 셋 다 **자리표시자다** — `Harvest.DROP_AMOUNT` 의 3 과 같은 자리이고, 제작(P3)이
## 수요에 값을 요구할 때 같이 정해진다. 값이 아니라 **순서가 규칙이다**:
## 나무 < 돌 < 광물. 검사는 값과 순서를 따로 묻는다.
const REGROW_DAYS := {
	TREE: 1.0,
	ROCK: 3.0,
	ORE: 7.0,
}

## 이 종류가 다시 자라는 데 걸리는 날 수. **0 이면 안 자란다** — 빈 칸이 그것이다.
static func regrow_days(kind: int) -> float:
	return REGROW_DAYS.get(kind, 0.0)

## ── 좌표 하나. **월드 전체를 안 만들고도 답이 나온다** ──────────────

static func at(world_seed: int, x: int, y: int) -> int:
	return at_height(world_seed, x, y, WorldGen.height_at(world_seed, x, y))

## 높이를 **이미 아는 쪽**(그리기·충돌)이 부르는 자리. 잡음을 두 번 풀지 않는다.
## 물이냐 땅이냐는 `WorldGen.kind_at_height` 가 정한다 — 여기서 다시 안 적는다.
static func at_height(world_seed: int, x: int, y: int, h: float) -> int:
	if WorldGen.kind_at_height(h) != WorldGen.LAND:
		return NONE                      # 바다에도 월드 밖에도 안 놓인다
	var sp := WorldGen.spawn_tile()
	if absi(x - sp.x) <= SPAWN_CLEAR and absi(y - sp.y) <= SPAWN_CLEAR:
		return NONE
	var u := WorldGen.unit(world_seed ^ PLACE_SALT, x, y)
	# 한 번 뽑은 값을 구간으로 가른다. 귀한 것부터 — 구간이 겹칠 수 없다.
	var ore := rate(ORE) if h > ORE_MIN_HEIGHT else 0.0
	if u < ore:
		return ORE
	var rock := ore + rate(ROCK)
	if u < rock:
		return ROCK
	if u < rock + tree_rate(world_seed, x, y):
		return TREE
	return NONE

## 이 칸에 나무가 설 확률. **숲 잡음이 정한다** — 검사가 읽으라고 밖으로 낸다.
static func tree_rate(world_seed: int, x: int, y: int) -> float:
	var f := FOREST_CELLS / float(WorldGen.SIZE)
	var n := WorldGen.value(world_seed ^ FOREST_SALT, x * f, y * f)
	return rate(TREE) * clampf(inverse_lerp(FOREST_FLOOR, 1.0, n), 0.0, 1.0)

## 몸이 지나갈 수 없는 칸인가. **셋 다 막는다** — 나무를 통과해 걸으면
## 도끼를 들 이유가 없다. 「무엇이 막나」를 아는 곳은 여기 한 군데다.
static func blocks(world_seed: int, x: int, y: int) -> bool:
	return at(world_seed, x, y) != NONE

## ── 월드 한 장 ────────────────────────────────────────────────────────

## SIZE*SIZE 바이트. 인덱스는 `WorldGen.generate` 와 같다 (y * SIZE + x).
static func generate(world_seed: int) -> PackedByteArray:
	var grid := PackedByteArray()
	grid.resize(WorldGen.SIZE * WorldGen.SIZE)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			grid[y * WorldGen.SIZE + x] = at(world_seed, x, y)
	return grid

## 구워 둔 한 장에서 꺼낸다. **밖은 NONE 이다** — 밖은 바다라 놓일 수가 없다.
## `WorldGen.at` 과 같은 함수다(밖이 0): 종류 상수가 둘 다 0 에서 시작하므로
## 한 벌만 둔다.
static func at_grid(grid: PackedByteArray, x: int, y: int) -> int:
	return WorldGen.at(grid, x, y)

## 종류별 칸 수. 자리 0 은 NONE 이다 — 합이 65536 이라 「어디로 샜나」가 보인다.
static func counts(grid: PackedByteArray) -> PackedInt32Array:
	var n := PackedInt32Array([0, 0, 0, 0])
	for v in grid:
		n[v] += 1
	return n
