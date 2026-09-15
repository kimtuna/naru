class_name WorldView
extends RefCounted

## 월드를 화면에 그리는 **순수 계산**. 노드도 캔버스도 안 본다 —
## 「어느 칸을 그리나」와 「그 칸이 무슨 색인가」 둘뿐이다.
##
## **보이는 칸만 그린다.** 월드는 256×256 = 65536 칸이고 한 화면에는 61 × 35 = 2135 칸이
## 걸린다 — 30배다. 통째로 그려도 **사람 눈에는 똑같아 보인다**. 그래서 main.gd 가
## 몇 칸을 그렸는지 세어 두고 `measure_window.gd` 의 DRAW 가 그 수를 잰다. 픽셀만 봐서는 못 잡는다.
##
## **오브젝트도 색이다** (회차 24): 나무·돌·광물은 그 칸을 통째로 제 색으로 칠한다.
## 그래서 「나무를 놓았는데 화면에 없다」가 **구운 픽셀에서** 빨개진다 —
## `measure_window.gd` 의 DRAW 가 픽셀을 `color_at` 과 맞추기 때문이다.
## 따로 스프라이트를 얹었다면 그 게이트가 통째로 눈을 감았을 것이다.
##
## **색이 곧 지형이다**, 지형 위에 덧칠한 것이 아니다:
##   - 물이냐 땅이냐는 **`WorldGen.tile_at` 이 정한다** — 충돌이 묻는 것과 글자 그대로
##     같은 함수다. 여기서 `h > SEA_LEVEL` 을 다시 쓰면 언젠가 한쪽만 고쳐져
##     **보이는 땅에 못 서는 날**이 온다
##   - 그 안에서의 명암은 높이(`height_at`)로 섞는다. 해수면에 가까울수록 얕고 밝아서
##     **해안선이 눈에 보인다**
##
## 칸마다 밝기를 아주 조금 흔든다(`TINT`). 두 가지 이유다:
##   - 16px 격자가 눈에 보여야 240 px/s 가 15칸/초로 보이는지 **사람이 걸어서 확인**한다
##   - 안 흔들면 한 화면이 거의 단색이라 `shot.sh --max-flat` 이 공허해진다
## **흔들기는 세 채널에 같은 양을 더한다.** 그래서 아래 부등식이 절대 안 뒤집힌다:
##   **물은 언제나 b > g > r · 빈 땅은 언제나 g > r > b**
##   **오브젝트가 선 땅은 b 가 제일 작다** — 색 셋 다 b 가 제일 작고, 바닥과 섞는 것도
##   볼록 결합이라 그 성질이 보존된다. **땅이 물처럼 보이는 일이 없다**는 것이 요점이다
## (`test_world_view.gd` 가 지킨다)

## 깊은 바다 → 얕은 바다.
const DEEP := Color(0.05, 0.12, 0.26)
const SHOAL := Color(0.13, 0.33, 0.52)

## 해안 → 안쪽 풀밭. 해수면 바로 위가 모래빛이라 물가가 밝게 테두리 진다.
const SHORE := Color(0.52, 0.56, 0.32)
const GRASS := Color(0.24, 0.43, 0.19)

## 명암을 다 쓰는 높이 구간. 실제 높이 범위(-0.90 .. 1.00)를 전부 쓰면
## 화면에 걸리는 좁은 구간이 전부 같은 색이 된다 — 눈에 보이는 쪽으로 좁혔다.
##
## **-0.25 는 고른 값이 아니라 계산된 값이다**: 월드 밖은 감쇠가 1.25 로 포화하므로
## 높이가 `0.35 + 0.65 - 1.25 = -0.25` 를 넘을 수 없다. 그래서 **월드 밖은 자동으로
## 정확히 `DEEP`** 이고, 따로 분기하지 않는다 (`test_outside_world_is_deep` 가 지킨다).
const DEEP_AT := -0.25
const HIGH_AT := 0.72

## 오브젝트 색. **셋 다 b 가 제일 작다** (위 부등식) · 서로 한눈에 갈린다.
const TREE_COLOR := Color(0.07, 0.22, 0.06)    # 풀밭보다 어둡다 — 숲이 덩어리로 보인다
const ROCK_COLOR := Color(0.58, 0.57, 0.54)    # 회색. 땅 중에 제일 밝다
const ORE_COLOR := Color(0.78, 0.56, 0.16)     # 호박색. 귀한 것이라 제일 튄다

## 오브젝트 칸에 **바닥이 비치는 몫**. 0 이면 나무 칸이 전부 같은 색 한 덩어리가 되고,
## 그러면 칸마다 흔드는 것(TINT)만 남아 `--max-flat` 과 색 수 게이트가 그만큼 헐거워진다.
## 높이에 따라 계속 변하는 지형색을 조금 섞어 두면 **오브젝트 칸도 제 색을 가진다**.
const GROUND_MIX := 0.30

## 칸마다 흔드는 밝기 폭 (±). 0.035 = 8비트로 ±9 — 격자는 보이고 얼룩지지는 않는다.
const TINT := 0.035

## 흔들기용 씨앗 어긋내기. 지형 잡음과 같은 해시를 그대로 쓰면 **잡음이 두 번 겹쳐**
## 큰 덩어리가 다시 보인다.
const TINT_SALT := 0x5bf03635

## ── 어느 칸을 그리나 ─────────────────────────────────────────────────

## 이 월드 범위(픽셀)에 걸리는 칸들. 경계에 걸친 칸도 포함한다 —
## 한 줄을 빼면 화면 가장자리에 배경색 띠가 생긴다.
static func tile_range(view: Rect2) -> Rect2i:
	var t := PlayerMotion.TILE
	var x0 := floori(view.position.x / t)
	var y0 := floori(view.position.y / t)
	var x1 := floori((view.position.x + view.size.x) / t)
	var y1 := floori((view.position.y + view.size.y) / t)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

static func tile_count(view: Rect2) -> int:
	var r := tile_range(view)
	return r.size.x * r.size.y

## ── 그 칸이 무슨 색인가 ──────────────────────────────────────────────

## `cleared` 는 **사람이 없앤 칸**이다 (회차 29 · `WorldState`). 그리는 쪽이 이미
## 아는 것을 여기서 다시 묻지 않는다: bool 하나면 되는데 배치를 되물으면 **한 칸마다
## 잡음을 한 번 더 푼다** — 한 화면이 2135칸이라 그대로 프레임 예산에 들어간다.
static func color_at(world_seed: int, x: int, y: int, cleared := false) -> Color:
	var c := base_color(world_seed, x, y, cleared)
	var d := (WorldGen.unit(world_seed ^ TINT_SALT, x, y) - 0.5) * 2.0 * TINT
	return Color(clampf(c.r + d, 0.0, 1.0), clampf(c.g + d, 0.0, 1.0), clampf(c.b + d, 0.0, 1.0))

## 흔들기 전의 색 — 지형, 그리고 그 위에 선 것.
## **높이를 한 번만 푼다**: 지형색도 오브젝트 배치도 같은 높이를 쓴다.
static func base_color(world_seed: int, x: int, y: int, cleared := false) -> Color:
	var h := WorldGen.height_at(world_seed, x, y)
	var ground := terrain_at_height(h)
	# **벤 칸은 도로 맨땅이다** (GDD A-4 · WorldObjects 머리말): 지형을 바꾸지 않고
	# 놓인 것만 지웠으므로, 색도 지형색 그대로 돌아간다.
	var kind := WorldObjects.NONE if cleared else WorldObjects.at_height(world_seed, x, y, h)
	if kind == WorldObjects.NONE:
		return ground
	return object_color(kind).lerp(ground, GROUND_MIX)

## 오브젝트 한 종류의 색 (바닥을 섞기 전).
static func object_color(kind: int) -> Color:
	match kind:
		WorldObjects.TREE: return TREE_COLOR
		WorldObjects.ROCK: return ROCK_COLOR
		WorldObjects.ORE: return ORE_COLOR
	return GRASS                         # NONE 은 여기까지 안 온다

## ── 바닥에 떨어진 것 ────────────────────────────────────────────────

## 바닥에 떨어진 것의 네모(월드 픽셀). **휘두르는 네모와 같은 반 칸**이다 —
## 벤 것이 손에 쥔 것과 같은 크기로 떨어져야 「저게 그거다」가 읽힌다.
## 칸을 통째로 칠하지 않는 것이 요점이다: 떨어진 것은 **땅 위에 놓인 물건**이라
## 둘레에 바닥이 보여야 하고, 안 그러면 나무를 벤 자리가 다른 오브젝트로 보인다.
## 색은 `HotbarView.item_color` 가 준다 — 핫바·손·바닥이 **한 곳에서** 나온다.
const DROP := PlayerMotion.TILE * 0.5

static func drop_rect(pos: Vector2) -> Rect2:
	return Rect2(pos - Vector2(DROP, DROP) * 0.5, Vector2(DROP, DROP))

## 흔들기 전의 지형색. 부등식을 재는 검사가 읽으라고 밖으로 냈다.
static func terrain_color(world_seed: int, x: int, y: int) -> Color:
	return terrain_at_height(WorldGen.height_at(world_seed, x, y))

## 높이 하나로 지형색을 낸다. **물이냐 땅이냐는 `WorldGen.kind_at_height` 가 정한다** —
## 충돌이 묻는 것과 글자 그대로 같은 문턱이다.
static func terrain_at_height(h: float) -> Color:
	if WorldGen.kind_at_height(h) == WorldGen.LAND:
		return SHORE.lerp(GRASS, _band(h, WorldGen.SEA_LEVEL, HIGH_AT))
	return DEEP.lerp(SHOAL, _band(h, DEEP_AT, WorldGen.SEA_LEVEL))

static func _band(v: float, lo: float, hi: float) -> float:
	return clampf(inverse_lerp(lo, hi, v), 0.0, 1.0)
