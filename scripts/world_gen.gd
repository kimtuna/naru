class_name WorldGen
extends RefCounted

## 월드의 **순수 생성**. 노드도 엔진 상태도 전역 RNG 도 안 본다 —
## 그래서 헤드리스로 잴 수 있고, **같은 씨앗은 언제 어디서나 같은 월드**다 (GDD D-1).
##
## **왜 RandomNumberGenerator 를 안 쓰나**: 그건 「순서」에 의존한다. 몇 번째로 뽑았느냐가
## 값을 정하므로, 나중에 타일 하나만 다시 묻거나 청크를 따로 만들면 월드가 달라진다.
## 여기는 **좌표를 넣으면 값이 나오는 해시**다 — 순서가 없으니 부분 생성도 같은 답을 준다.
##
## 지형은 두 종류뿐이다: 물(0) 과 땅(1). **그 위에 무엇이 놓이나는 `WorldObjects` 다** —
## 나무 한 그루가 지형을 바꾸지는 않는다 (베면 도로 풀밭이다).
##
## **섬 모양은 수학이 보장한다**, 운이 아니다:
##   - 가장자리는 항상 물   — 감쇠 1.25 가 잡음 최대 1.0 보다 크다
##   - 한가운데는 항상 땅   — 잡음 바닥 0.35 가 해수면 0.30 보다 크다
## 두 줄 다 검사가 여러 씨앗으로 지킨다.

const SIZE := 256              # 한 변의 타일 수 (GDD D-1: 1판은 256×256 · 섬 하나)
const WATER := 0
const LAND := 1

const SEA_LEVEL := 0.30        # 이 높이 이하는 물
const NOISE_FLOOR := 0.35      # 잡음을 0..1 에서 0.35..1.0 으로 들어올린다 (가운데 보장)
const FALLOFF_GAIN := 1.25     # 가장자리에서 빼는 양 (> 잡음 최대 1.0 이라 테두리는 물)
const FALLOFF_POW := 3.0       # 클수록 해안이 가파르고 섬이 넓어진다
const CONTRAST := 2.5          # 잡음을 평균 0.5 에서 벌린다. 1.0 이면 해안이 동그래진다
const OCTAVES := 4
const BASE_CELLS := 3.5        # 월드 한 변에 들어가는 잡음 칸 수 (1칸 ≈ 73타일)

## ── 좌표 하나의 지형. **월드 전체를 안 만들고도 답이 나온다** ──────────────

static func tile_at(world_seed: int, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return WATER                     # 월드 밖은 바다다. 예외를 던지지 않는다
	return kind_at_height(height_at(world_seed, x, y))

## 높이 → 지형. **해수면 문턱을 아는 곳이 여기 한 군데다.**
##
## 왜 밖에 냈나: 그리기도 충돌도 오브젝트도 **높이를 이미 손에 들고** 있다 —
## 그때마다 `tile_at` 을 부르면 잡음을 통째로 한 번 더 푼다 (한 칸 fbm 16회).
## 그렇다고 부르는 쪽이 `h > SEA_LEVEL` 을 다시 적으면 **언젠가 한쪽만 고쳐져
## 보이는 땅에 못 서는 날**이 온다. 문턱은 한 군데 두고 높이만 넘긴다.
##
## **월드 밖을 따로 안 본다**: 감쇠가 1.25 로 포화해서 밖의 높이는 -0.25 를 못 넘는다 —
## 해수면 0.30 아래라 저절로 물이다 (NUMBERS 6절의 부등식).
static func kind_at_height(h: float) -> int:
	return LAND if h > SEA_LEVEL else WATER

## 높이. 검사와 대조군이 읽으라고 밖으로 낸다.
static func height_at(world_seed: int, x: int, y: int) -> float:
	var n := clampf((_fbm(world_seed, float(x), float(y)) - 0.5) * CONTRAST + 0.5, 0.0, 1.0)
	return NOISE_FLOOR + (1.0 - NOISE_FLOOR) * n - _falloff(x, y)

## 중심에서의 거리에 따라 빼는 양. 0 = 한가운데, 1 이상 = 테두리.
static func _falloff(x: int, y: int) -> float:
	var half := (SIZE - 1) * 0.5
	var d := Vector2(x - half, y - half).length() / half
	return FALLOFF_GAIN * pow(minf(d, 1.0), FALLOFF_POW)

## ── 월드 한 장 ────────────────────────────────────────────────────────

## SIZE*SIZE 바이트. 인덱스는 y * SIZE + x 다.
static func generate(world_seed: int) -> PackedByteArray:
	var grid := PackedByteArray()
	grid.resize(SIZE * SIZE)
	for y in SIZE:
		for x in SIZE:
			grid[y * SIZE + x] = tile_at(world_seed, x, y)
	return grid

static func at(grid: PackedByteArray, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
		return WATER
	return grid[y * SIZE + x]

static func land_count(grid: PackedByteArray) -> int:
	var n := 0
	for v in grid:
		if v == LAND:
			n += 1
	return n

## 월드 한 장을 한 숫자로 줄인다 (FNV-1a 32비트).
## **프로세스가 달라도 같은 값이어야 한다** — 그걸 measure_world.gd 가 잰다.
static func checksum(grid: PackedByteArray) -> int:
	var h := 2166136261
	for v in grid:
		h = ((h ^ v) * 16777619) & 0xFFFFFFFF
	return h

## 플레이어가 서는 칸. 한가운데는 위 두 상수가 땅임을 보장한다.
static func spawn_tile() -> Vector2i:
	return Vector2i(SIZE / 2, SIZE / 2)

## ── 잡음 ──────────────────────────────────────────────────────────────

## 좌표 → 0..1. 순서가 없는 순수 함수다.
## **밖으로 냈다**: 타일 색을 칸마다 조금 흔드는 데 WorldView 가 같은 해시를 쓴다 —
## 두 벌을 두면 언젠가 한쪽만 고쳐진다.
static func unit(world_seed: int, x: int, y: int) -> float:
	var h := world_seed & 0xFFFFFFFF
	h = (h ^ (x * 374761393)) & 0xFFFFFFFF
	h = (h ^ (y * 668265263)) & 0xFFFFFFFF
	h = (h ^ (h >> 13)) & 0xFFFFFFFF
	h = (h * 1274126177) & 0xFFFFFFFF
	h = (h ^ (h >> 16)) & 0xFFFFFFFF
	return float(h) / 4294967295.0

## 격자점 네 개를 smoothstep 으로 섞는다.
## **밖으로 냈다**: `WorldObjects` 가 숲의 뭉침을 같은 잡음으로 만든다 —
## `unit` 과 같은 이유다 (두 벌을 두면 언젠가 한쪽만 고쳐진다).
static func value(world_seed: int, x: float, y: float) -> float:
	var xi := floori(x)
	var yi := floori(y)
	var fx := x - xi
	var fy := y - yi
	var u := fx * fx * (3.0 - 2.0 * fx)
	var v := fy * fy * (3.0 - 2.0 * fy)
	var a := unit(world_seed, xi, yi)
	var b := unit(world_seed, xi + 1, yi)
	var c := unit(world_seed, xi, yi + 1)
	var d := unit(world_seed, xi + 1, yi + 1)
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)

## 옥타브를 겹친다. 큰 덩어리가 섬을, 작은 것이 해안선의 들쭉날쭉을 만든다.
static func _fbm(world_seed: int, x: float, y: float) -> float:
	var freq := BASE_CELLS / float(SIZE)
	var amp := 1.0
	var sum := 0.0
	var norm := 0.0
	for o in OCTAVES:
		# 옥타브마다 씨앗을 어긋내지 않으면 층이 겹쳐 격자 무늬가 보인다.
		sum += amp * value(world_seed + o * 1013904223, x * freq, y * freq)
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return sum / norm
