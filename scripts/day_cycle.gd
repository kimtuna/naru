class_name DayCycle
extends RefCounted

## 시계 하나를 **빛 하나**로 바꾸는 순수 계산 (GDD G-1b — 하루 20분 = 낮 10 + 밤 10).
## 노드도 캔버스도 안 본다: 들어가는 것은 `WorldState.now` 하나, 나오는 것은 색 하나다.
##
## **하루 길이를 여기 다시 적지 않는다** — `WorldState.DAY_SEC` 를 읽는다.
## 회차 30 이 「낮밤이 오면 고칠 것은 `DAY_SEC` 한 줄이다」라고 적어 둔 그 줄이다.
## 두 군데에 초를 적으면 다시 자라는 나무와 해가 **서로 다른 하루**를 살게 되고,
## 어긋나도 아무 데서도 안 터진다.
##
## ── 어떻게 화면에 얹히나 — **칸 색을 고치지 않는다** ────────────────
## 밤을 칸 색에 섞으면 `main.gd` 의 색 캐시(2135칸 × 3.32 µs = 7.9 ms)를 **매 프레임**
## 다시 채워야 한다. 빛은 계속 변하니까 캐시가 통째로 무의미해지고 한 프레임 예산
## 16667 µs 를 절반 넘게 먹는다. 그래서 `CanvasModulate` 한 장으로 곱한다 —
## 공짜고, `WorldView` 는 **낮의 색만** 알면 된다.
## **핫바는 안 어두워진다**: `UI` 가 제 `CanvasLayer` 라 이 곱이 안 닿는다.
## 밤에 가방이 안 보이면 그건 연출이 아니라 고장이다.
##
## ── 밤빛은 **색을 거의 안 돌린다** ──────────────────────────────────
## 파란 달빛이 그림 같겠지만, 곱하기는 `WorldView` 의 부등식을 **뒤집을 수 있다**:
## 「물은 b > g > r · 땅과 그 위의 것은 b 가 제일 작다」가 「땅이 물처럼 보이지 않는다」를
## 떠받치고 있는데, 돌 색(0.58, 0.57, 0.54)은 r 과 b 의 여유가 10% 도 안 된다.
## 밤빛의 b/r 이 그 여유를 넘는 순간 **달빛 아래 바위가 웅덩이가 된다.**
## 그래서 아주 조금만 차갑게 한다 — 여유는 `test_day_cycle.gd` 가 실제 월드 칸으로 잰다.

## 판이 시작하는 시각. **0.25 = 한낮**이라 `now = 0` 의 빛이 정확히 흰색이고,
## 첫 밤까지 10분이 온전히 남는다 (GDD B-5 「첫 30분」).
## 덤: 화면 게이트(DRAW)가 띄우자마자 재는 자리가 곱이 1 인 자리라,
## 「월드를 제 색으로 그렸나」와 「밤에 어두워지나」가 서로를 흐리지 않는다.
const START_PHASE := 0.25

## 해가 뜨고 지는 데 걸리는 **하루의 몫**. 0.08 × 1200초 = 96초.
## **경계에 가운데를 맞춘다** — 램프의 절반은 낮 쪽, 절반은 밤 쪽이라
## 낮 10분 · 밤 10분이 정확히 반반으로 남는다. 한쪽 끝에 붙이면 GDD 의 10/10 이 깨진다.
const TWILIGHT := 0.08

## 한낮의 빛. 곱해서 아무것도 안 바꾼다 — **낮 화면은 `WorldView` 의 색 그대로다.**
const DAY_LIGHT := Color(1.0, 1.0, 1.0)

## 한밤의 빛. 밝기는 0.30 쯤이고 b/r 은 **1.071** 이다 (머리말의 여유 · 돌이 1.09).
## 더 파랗게 하고 싶으면 `test_day_cycle.gd` 가 먼저 빨개진다.
const NIGHT_LIGHT := Color(0.28, 0.29, 0.30)

## 하루 안의 어디인가. 0 = 해 뜨는 한가운데 · 0.25 = 한낮 · 0.5 = 해 지는 한가운데.
## **음수 시각도 답이 있다**(`fposmod`) — 저장을 불러오는 자리가 시계를 되감을 수 있다.
static func phase(now: float) -> float:
	return fposmod(now / WorldState.DAY_SEC + START_PHASE, 1.0)

## 낮인가. **[0, 0.5) 이 낮이다** — 램프가 경계에 걸쳐 있어도 이 문장은 안 흔들린다.
## 조건부 스폰(GDD B-3 「밤에만 나오는 것이 있다」)이 물을 자리라 빛이 아니라
## **구간**으로 답한다: 「얼마나 어두우냐」로 스폰을 가르면 문턱이 또 하나 생긴다.
static func is_day(now: float) -> bool:
	return phase(now) < 0.5

## 0 = 한밤 · 1 = 한낮. 빛을 섞는 몫이자 **밝기의 이름**이다.
static func daylight(now: float) -> float:
	return daylight_of_phase(phase(now))

## 지금 화면에 곱할 색.
static func light_at(now: float) -> Color:
	return light_of_phase(phase(now))

static func light_of_phase(p: float) -> Color:
	return NIGHT_LIGHT.lerp(DAY_LIGHT, daylight_of_phase(p))

## **경계에서 얼마나 낮 쪽으로 들어왔나**(하루의 몫). 낮이면 +, 밤이면 −,
## 해가 뜨거나 지는 순간이 정확히 0 이다. 두 경계(0.0 · 0.5) 중 가까운 쪽에서 잰다.
static func into_day(p: float) -> float:
	if p < 0.5:
		return minf(p, 0.5 - p)
	return -minf(p - 0.5, 1.0 - p)

## 그 몫을 밝기로. 램프 폭 `TWILIGHT` 의 절반씩을 경계 양쪽에 쓰고,
## 양 끝은 `smoothstep` 으로 눕힌다 — 안 그러면 해가 다 뜬 순간에 밝기가 꺾여
## 화면이 **한 프레임 튄다.**
static func daylight_of_phase(p: float) -> float:
	var t := clampf(0.5 + into_day(p) / TWILIGHT, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
