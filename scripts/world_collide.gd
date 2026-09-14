class_name WorldCollide
extends RefCounted

## 타일 격자와의 충돌 **순수 계산**. 노드도 물리 엔진도 안 본다 —
## 그래서 헤드리스로 잴 수 있고, **같은 입력이 언제나 같은 자리를 준다.**
##
## **왜 물리 엔진(`move_and_slide`)을 안 쓰나**: 월드는 256×256 = 65536 칸이고,
## 그중 절반 넘게가 바다다. 정적 몸을 그만큼 세울 수는 없다. 창 주변만 세우는 방법도
## 있지만 그러면 **결과가 「지금 무엇이 세워져 있나」에 달린다** — 같은 씨앗이 같은 월드를
## 주는 이유(GDD D-1)와 원정 보고를 서버가 되짚는 구조(GDD C-4)는 둘 다
## **재현 가능한 이동**을 전제한다. 여기는 격자에 대고 푸는 것이라 프레임률·빌드와 무관하다.
##
## **막는 칸이 무엇인지는 여기가 안 정한다.** `solid` Callable(칸 좌표 → bool)을 받는다 —
## 바다와 **땅에 선 것**(나무·돌·광물)이 같은 자리에 얹힌다. 검사도 손으로 만든 지도를 넣는다.
##
## ── 미끄러짐은 **축을 따로 푸는 것**에서 나온다 ──────────────────────
## x 를 풀고 y 를 푼다. 해안에 비스듬히 붙으면 막힌 축만 죽고 나머지 축은 그대로 간다 —
## 「벽에 붙었으니 전부 정지」가 아니다. 속력을 다시 정규화하지도 않는다:
## 대각 240 의 한 축은 169.71 이고, 벽을 타면 그 169.71 로 간다.

## 몸 반크기. **네모가 아니라 직사각형이다** (바퀴 16) — 발밑 상자다.
##
##   x = 6   타일 반(8)보다 작아야 한다 — 같으면 16px 통로를 지날 때 부동소수 한 톨에
##           걸려 낀다. 2px 씩 여유를 둔 값이라 **몸통 1칸 폭보다 2px 좁다**.
##           **2px 은 타일을 안 따라간다** — 이 여유가 곧 「벽에 붙었을 때 네모가 막힌 칸에
##           걸치는 몫」(1.99px)이라 사람 눈에 보이는 절대 크기다
##   y = 4   **발밑 반 칸**. 그리는 네모는 2칸 키인데 상자는 그 아래끝 반 칸뿐이다 —
##           머리가 위 칸에 걸쳐도 막히지 않는다 (코어 키퍼 관례 · GDD E-1)
##
## **타일에서 따라 나온다** — 고정값이 바뀌면(바퀴 15 의 48 → 32 · 바퀴 17 의 32 → 16)
## 여기도 따라와야 하는데 숫자를 박아 두면 안 따라온다. 그러면 몸이 통로보다 넓어져
## 1칸 통로에 낀다.
const HALF := Vector2(PlayerMotion.TILE * 0.5 - 2.0, PlayerMotion.TILE * 0.25)

## 벽에 붙일 때 남기는 틈. 0 이면 붙은 칸이 「겹친 칸」으로 읽혀 다음 프레임이 흔들린다.
const EPS := 0.01

## ── 쓰는 자리 ────────────────────────────────────────────────────────

## 씨앗 하나로 「이 칸이 막나」를 묻는 Callable 을 만든다.
## **칸 좌표는 월드 칸이다** — 카메라가 오면서(P1-6) 화면 칸과 갈라질 일이 없어졌다.
##
## **바다 + 땅에 선 것.** 나무를 통과해 걸을 수 있으면 도끼를 들 이유가 없다.
## 높이를 한 번만 풀어 둘 다에 쓴다 — 한 물리 틱에 네 번쯤 묻는 자리다.
static func solid_from_seed(world_seed: int) -> Callable:
	return func(tx: int, ty: int) -> bool:
		var h := WorldGen.height_at(world_seed, tx, ty)
		if WorldGen.kind_at_height(h) == WorldGen.WATER:
			return true
		return WorldObjects.at_height(world_seed, tx, ty, h) != WorldObjects.NONE

## `pos` 에서 `motion` 만큼 가려다 막히면 벽 앞에 멈춘 자리를 준다.
## `solid` 가 비어 있으면 아무것도 안 막는다 — 월드 없이 띄운 씬이 그대로 움직인다.
static func move(pos: Vector2, motion: Vector2, solid: Callable, half := HALF) -> Vector2:
	if not solid.is_valid():
		return pos + motion
	var p := pos
	p.x = _sweep(p, motion.x, 0, solid, half)
	p.y = _sweep(p, motion.y, 1, solid, half)
	return p

## 몸 네모가 막는 칸과 겹치나. 「바다에 들어갔나」를 재는 자리다.
static func overlaps(pos: Vector2, solid: Callable, half := HALF) -> bool:
	if not solid.is_valid():
		return false
	for ty in range(tile_of(pos.y - half.y + EPS), tile_of(pos.y + half.y - EPS) + 1):
		for tx in range(tile_of(pos.x - half.x + EPS), tile_of(pos.x + half.x - EPS) + 1):
			if solid.call(tx, ty):
				return true
	return false

## 픽셀 좌표가 몇 번째 칸인가. 음수에서도 맞아야 해서 나눗셈이 아니라 floor 다.
static func tile_of(v: float) -> int:
	return floori(v / PlayerMotion.TILE)

## ── 한 축 풀기 ───────────────────────────────────────────────────────

## `axis` 0=x, 1=y. 지나가는 칸을 **한 줄씩 전부** 본다 — 한 틱에 여러 칸을 건너뛰는
## 속도(빠른 탈것·낮은 프레임률)에서도 벽을 뚫지 않는다.
##
## **상자가 직사각형이라 축마다 반크기가 다르다** (바퀴 16): 앞모서리는 진행 축의 반크기고,
## 검사할 줄의 범위는 **옆축**의 반크기다. 하나로 뭉뚱그리면 발밑 상자가 네모로 되돌아간다.
static func _sweep(pos: Vector2, d: float, axis: int, solid: Callable, half: Vector2) -> float:
	if is_zero_approx(d):
		return pos[axis]
	var step := 1 if d > 0.0 else -1
	var edge := half[axis] * step                 # 진행 방향 앞모서리
	var back := EPS * step                        # 모서리를 칸 안쪽으로 한 톨 당긴다
	# 옆축이 걸치는 칸의 범위. 이 줄들만 검사하면 된다.
	var lo := tile_of(pos[1 - axis] - half[1 - axis] + EPS)
	var hi := tile_of(pos[1 - axis] + half[1 - axis] - EPS)
	var first := tile_of(pos[axis] + edge - back) + step
	var last := tile_of(pos[axis] + d + edge - back)
	var c := first
	while (c - last) * step <= 0:
		for o in range(lo, hi + 1):
			var tx := c if axis == 0 else o
			var ty := o if axis == 0 else c
			if solid.call(tx, ty):
				# 막는 칸의 앞면에 몸을 붙인다.
				var wall := float(c if step > 0 else c + 1) * PlayerMotion.TILE
				var stop := wall - edge - back
				# 이미 겹친 채 시작했으면 뒤로 밀지 않는다 — 갇히지 않게.
				return maxf(pos[axis], stop) if step > 0 else minf(pos[axis], stop)
		c += step
	return pos[axis] + d
