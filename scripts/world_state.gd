class_name WorldState
extends RefCounted

## 씨앗이 만든 월드 위에 얹히는 **사람이 바꾼 것**. 지금은 둘이다:
## **없어진 칸**(벤 나무)과 **바닥에 떨어진 것**(목재).
##
## **회차 24 가 남긴 물음의 답이다** — 「벤 자리를 어디에 적나」.
## 배치(`WorldObjects`)는 좌표를 넣으면 답이 나오는 순수 해시라 상태가 없다:
## 「이 칸의 나무는 없어졌다」를 적을 자리가 코드 어디에도 없었다.
##
## **씨앗 월드를 고치지 않는다.** 없앤 칸의 **목록**만 들고, 물으면 그 위에 덮어서
## 답한다. 두 가지가 여기서 나온다:
##   - 월드 저장(BACKLOG P2d)은 이 두 개만 적으면 된다 — 지형과 배치는 씨앗 하나로
##     글자까지 같게 다시 나온다 (GDD D-1). 65536칸을 적는 저장이 아니다
##   - **나무가 다시 자라는 것**(GDD A-4 「한 번 캐고 끝나는 자원이 없다」)이
##     목록에서 한 칸을 지우는 것으로 끝난다 — 원래 무엇이 있었는지는 안 잃는다
##
## ── 시계가 여기 산다 (회차 30) ───────────────────────────────────────
## 다시 자라는 데 필요한 것은 **시간**이었다. 시계를 밖(main.gd)에 두면 저장이
## 「벤 목록」과 「그때가 언제였나」를 서로 다른 두 곳에서 꺼내 맞춰야 한다 —
## 한쪽만 실으면 세이브를 불러오는 순간 온 섬이 동시에 자란다.
## 그래서 **`now` 와 벤 시각을 같은 몸에 둔다**: 저장은 여전히 「이 하나」다.
##
## **하루 길이만 여기 있고 「몇 날이냐」는 배치가 안다** (`WorldObjects.REGROW_DAYS`).
## 낮밤(BACKLOG)이 오면 고칠 것은 `DAY_SEC` 한 줄이다.
##
## **막는 칸도 여기서 나온다.** 벤 나무가 계속 몸을 막으면 「베었다」가 거짓말이 된다 —
## 그래서 `solid()` 이 없어진 칸을 같이 본다. 규칙 자체는 `WorldCollide` 에 한 벌만 있다.

## 어느 칸이 어떻게 바뀌었는지 알린다. **화면을 다시 칠하는 쪽이 이걸 듣는다** —
## main.gd 의 색 캐시는 「보이는 범위가 바뀔 때만」 다시 채우므로, 제자리에 선 채로
## 나무를 베면 **캐시가 상한 줄 모른다.**
signal changed(tile: Vector2i)

## 게임 내 하루 (GDD G-1b — 20분 = 낮 10 + 밤 10). **낮밤 주기가 오면 그쪽이 이 값을
## 읽어 간다** — 지금은 「하루」라는 단위가 필요한 곳이 다시 자라는 것뿐이다.
const DAY_SEC := 1200.0

## 몸이 그 칸에 서 있어서 못 자랐을 때 **다시 물어보기까지의 시간**.
## 매 프레임 다시 묻지 않는 이유는 비용이 아니라 **줄 서기**다: 못 자란 칸을 큐 맨 앞에
## 그대로 두면 그 뒤의 칸들이 영영 제 차례를 못 본다.
## 1초는 사람이 못 느끼는 길이다 — 비켜서면 그 자리에서 자란 것처럼 보인다.
const RETRY_SEC := 1.0

var world_seed: int

## 없어진 칸. `Vector2i` → **다시 자랄 시각**(게임 초). 안 자라는 것은 `INF` 다.
## **없는 칸이 곧 안 바뀐 칸**이라 빈 사전이 기본이다.
## 값이 true 가 아니라 시각인 이유: 막는 쪽(`WorldCollide`)은 `has()` 만 보므로
## 값을 무엇으로 두든 같은데, **벤 시각을 따로 든 사전을 하나 더 만들면** 둘이
## 어긋나서 「목록에는 있는데 언제 자라는지 모르는 칸」이 생긴다.
var cleared := {}

## 이 월드가 시작하고 흐른 **게임 시간(초)**. `tick()` 만 움직인다 —
## `Time.get_ticks` 를 안 쓴다: 그러면 저장을 불러온 판이 「그동안 흐른 시간」을
## 현실 시계에서 주워 와 온 섬이 한꺼번에 자란다 (GDD D-1 재현성).
var now := 0.0

## 「이 칸에 몸이 서 있나」. 월드를 아는 쪽(main.gd)이 꽂아 준다.
## **비어 있으면 아무도 안 막는다** — 월드만 세우는 검사가 그대로 돈다.
var occupied := Callable()

## 다시 자랄 것들, **자랄 시각 순**. 매 프레임 `cleared` 를 통째로 훑지 않으려고 둔다 —
## 판이 길어질수록 벤 칸은 늘어나는데 프레임 예산은 그대로다 (main.gd 의 16667 µs).
## 맨 앞만 보면 되고, 철 지난 기록은 **지우지 않고 넘긴다**(`cleared` 의 시각과
## 안 맞으면 버린다): 가운데를 지우는 것이 넣는 것보다 비싸다.
var _due: Array[Dictionary] = []

## 바닥에 떨어진 것. `{id, amount, pos}` 의 목록 — **순서가 곧 떨어진 순서**다.
## 줍기(BACKLOG P2)가 이 목록을 먹는다. 여기서는 쌓거나 합치지 않는다:
## 합치는 규칙은 가방의 것이고(`Inventory`), 바닥은 그냥 놓인 자리다.
var drops: Array[Dictionary] = []

func _init(seed_value: int) -> void:
	world_seed = seed_value

## ── 무엇이 놓여 있나 ─────────────────────────────────────────────────

## 이 칸에 지금 서 있는 것. **없앤 칸은 NONE 이다.**
func object_at(x: int, y: int) -> int:
	if cleared.has(Vector2i(x, y)):
		return WorldObjects.NONE
	return WorldObjects.at(world_seed, x, y)

## 씨앗이 **원래** 놓았던 것. 없앤 뒤에도 답이 남는다 — 다시 자라게 할 때 읽는다.
func original_at(x: int, y: int) -> int:
	return WorldObjects.at(world_seed, x, y)

func is_cleared(x: int, y: int) -> bool:
	return cleared.has(Vector2i(x, y))

func cleared_count() -> int:
	return cleared.size()

## ── 바꾸기 ───────────────────────────────────────────────────────────

## 이 칸의 것을 없앤다. 돌려주는 것은 **없앤 종류**다 — NONE 이면 아무 일도 안 했다.
## **빈 칸을 지웠다고 적지 않는다**: 목록이 「바꾼 것」이 아니라 「클릭한 자리」가 되면
## 저장이 자꾸 커지고, 다시 자라게 할 때 무엇을 되돌릴지도 흐려진다.
func clear_object(x: int, y: int) -> int:
	var kind := object_at(x, y)
	if kind == WorldObjects.NONE:
		return WorldObjects.NONE
	var tile := Vector2i(x, y)
	# **언제 다시 자랄지는 없앨 때 정해진다** — 나중에 물으면 「무엇이 있었나」를
	# 다시 풀어야 하고, 그 사이에 규칙이 바뀌면 이미 벤 칸이 소급해서 달라진다.
	var days := WorldObjects.regrow_days(kind)
	_schedule(tile, (now + days * DAY_SEC) if days > 0.0 else INF)
	changed.emit(tile)
	return kind

## 바닥에 떨군다. **개수가 0 이하면 아무것도 안 놓는다** — 빈 더미가 바닥에 남으면
## 줍는 쪽이 「주웠는데 아무것도 안 들어왔다」를 보게 된다.
func add_drop(id: StringName, amount: int, pos: Vector2) -> bool:
	if id == Inventory.EMPTY or amount <= 0:
		return false
	drops.append({"id": id, "amount": amount, "pos": pos})
	return true

func drop_count() -> int:
	return drops.size()

## 바닥에 있는 그 아이디의 총 개수. 검사가 「삼키지 않았나」를 묻는 자리다.
func dropped_total(id: StringName) -> int:
	var n := 0
	for d in drops:
		if d["id"] == id:
			n += int(d["amount"])
	return n

## ── 시간이 흐른다 (GDD A-4) ──────────────────────────────────────────

## 게임 시간을 `delta` 초만큼 흘리고, **때가 된 칸을 되돌린다.**
## 돌려주는 것은 **이번에 다시 자란 칸 수**다 — 0 이 흔한 값이다.
##
## 한 번에 큰 `delta` 를 넣어도 맞다(세이브를 불러오는 자리 · 실측 게이트):
## 큐가 시각 순이라 밀린 것이 **밀린 순서대로** 한꺼번에 나온다.
func tick(delta: float) -> int:
	if delta <= 0.0:
		return 0                       # 시간은 뒤로 안 간다
	now += delta
	var grown := 0
	while not _due.is_empty() and float(_due[0]["at"]) <= now:
		var e: Dictionary = _due.pop_front()
		var tile: Vector2i = e["tile"]
		# 철 지난 기록. 다시 베였거나(시각이 새로 적혔다) 이미 자랐다.
		if cleared.get(tile, INF) != e["at"]:
			continue
		# **몸이 서 있으면 안 자란다.** 여기가 없으면 나무가 사람 안에서 자라서
		# 「벤 자리에 몸이 낀다」가 된다 — 이 파일이 막으려고 있는 바로 그것이다.
		if occupied.is_valid() and occupied.call(tile):
			_schedule(tile, now + RETRY_SEC)
			continue
		cleared.erase(tile)
		changed.emit(tile)             # 화면을 다시 칠하게 한다 (main.gd 의 색 캐시)
		grown += 1
	return grown

## 이 칸이 다시 자랄 시각. 안 없앤 칸도 안 자라는 칸도 `INF` 다.
func regrow_at(x: int, y: int) -> float:
	return cleared.get(Vector2i(x, y), INF)

## 없앤 칸 하나를 「이때 자란다」로 적는다. **`cleared` 와 큐를 같이 적는 유일한 자리다.**
## 시각을 이진 탐색으로 끼워 넣어 큐를 정렬된 채로 둔다 — 종류마다 자라는 시간이
## 다르면 넣는 순서가 곧 시각 순이 아니다.
func _schedule(tile: Vector2i, at: float) -> void:
	cleared[tile] = at
	if is_inf(at):
		return                         # 안 자라는 것은 줄을 안 선다
	var lo := 0
	var hi := _due.size()
	while lo < hi:
		var mid := (lo + hi) >> 1
		if float(_due[mid]["at"]) <= at:
			lo = mid + 1
		else:
			hi = mid
	_due.insert(lo, {"tile": tile, "at": at})

## ── 몸이 지나갈 수 없는 칸 ───────────────────────────────────────────

## 「이 칸이 막나」. **없앤 칸은 안 막는다.**
## 규칙은 `WorldCollide` 에 한 벌뿐이다 — 여기서 바다·오브젝트를 다시 적으면
## 언젠가 한쪽만 고쳐져서 **벤 자리에 몸이 낀다.**
## `cleared` 를 **그대로** 넘긴다(사전은 참조다): 벨 때마다 Callable 을 다시 만들면
## 이미 꽂아 둔 플레이어가 옛 목록을 계속 본다.
func solid() -> Callable:
	return WorldCollide.solid_from_seed(world_seed, cleared)
