extends TestBase

## **사람이 차지한 칸**의 목록을 잰다 (GDD A-4 · 회차 32).
##
## 여기가 지키는 한 문장: **빠뜨린 등록은 조용히 지나가지 않는다.**
## 「이 칸에 임자가 있나」를 여러 곳이 각자 답하면 언젠가 한 곳이 빠지고, 그 결과는
## **집 거실에 나무가 서는 것**이다 — 그런데 그 회차의 검사는 전부 초록이다.
## 그래서 선언(`Claim.KINDS`)과 배선(`add`)을 갈라 놓고 **둘이 안 맞는 것을 센다**.
##
## 진짜 씬이 정말로 꽂았는지는 여기서 못 본다 — 그건 `measure_regrow.gd` 의 몫이다.

const T := Vector2i(10, 20)
const U := Vector2i(11, 20)

## ── 빈 목록 ──────────────────────────────────────────────────────────

## **아무도 안 꽂은 목록은 아무 칸도 안 막는다.** 여기가 true 로 기울면 온 섬이
## 「차지된 칸」이 되어 나무가 한 그루도 안 자란다 — GDD A-4 가 통째로 사라진다.
func test_an_empty_claim_covers_nothing() -> void:
	var c := Claim.new()
	eq(c.count(), 0, "꽂힌 출처의 수")
	check(not c.covers(T), "빈 목록이 칸을 막는다")
	eq(c.holder(T), &"", "빈 목록의 임자")

## **아무것도 안 꽂았으면 선언한 것 전부가 빠진 것이다.** `missing()` 이 늘 빈 배열을
## 주면 계약이 아니라 장식이다 — 이 검사가 그 자리를 막는다.
func test_nothing_wired_means_every_kind_is_missing() -> void:
	var c := Claim.new()
	eq(c.missing().size(), Claim.KINDS.size(), "아무것도 안 꽂았을 때 빠진 종류의 수")
	check(c.missing().has(Claim.BODY), "몸이 빠진 목록에 없다")

## ── 꽂기 ─────────────────────────────────────────────────────────────

## 몸 하나를 꽂으면 **그 칸만** 막는다. 옆 칸까지 막으면 숲이 사람을 따라다니며 사라진다
## (반경은 아직 안 정했다 — 설치물이 생긴 뒤 눈으로 정한다).
func test_one_source_covers_only_its_own_tile() -> void:
	var c := Claim.new()
	check(c.add(Claim.BODY, func(tile: Vector2i) -> bool: return tile == T), "몸을 못 꽂았다")
	eq(c.count(), 1, "꽂힌 출처의 수")
	check(c.covers(T), "몸이 선 칸을 안 막는다")
	check(not c.covers(U), "옆 칸까지 막는다")
	eq(c.holder(T), Claim.BODY, "그 칸의 임자")
	eq(c.missing().size(), 0, "몸을 꽂은 뒤 빠진 종류의 수")

## **출처가 둘이면 둘 다 묻는다.** 첫 번째에서 멈추면 나중에 꽂은 설치물이
## 영영 안 물어지고, 「등록은 했는데 안 본다」가 된다.
func test_every_source_is_asked_and_the_holder_is_named() -> void:
	var c := Claim.new()
	c.add(Claim.BODY, func(tile: Vector2i) -> bool: return tile == T)
	# 가짜 설치물. 제작대(P3)가 생기기 전에도 **두 번째 출처**를 잴 수 있다.
	c.add(&"가짜 설치물", func(tile: Vector2i) -> bool: return tile == U)
	eq(c.count(), 2, "꽂힌 출처의 수")
	check(c.covers(T), "몸이 선 칸을 안 막는다")
	check(c.covers(U), "설치물이 선 칸을 안 막는다 (두 번째 출처를 안 묻는다)")
	check(not c.covers(Vector2i(50, 50)), "아무도 없는 칸을 막는다")
	eq(c.holder(U), &"가짜 설치물", "설치물이 선 칸의 임자")
	eq(c.holder(Vector2i(50, 50)), &"", "빈 칸의 임자")

## **묻는 순서는 꽂은 순서다.** 두 출처가 같은 칸을 차지하면 먼저 꽂은 쪽이 답한다 —
## 사전 순이나 해시 순이면 게이트의 실패 메시지가 판마다 달라진다.
func test_the_first_wired_source_answers_first() -> void:
	var c := Claim.new()
	c.add(Claim.BODY, func(tile: Vector2i) -> bool: return tile == T)
	c.add(&"가짜 설치물", func(tile: Vector2i) -> bool: return tile == T)
	eq(c.holder(T), Claim.BODY, "둘이 겹친 칸의 임자")
	eq(c.names(), [Claim.BODY, &"가짜 설치물"] as Array[StringName], "꽂힌 순서")

## ── 거절 ─────────────────────────────────────────────────────────────

## **같은 이름을 두 번은 안 받는다.** 덮어쓰게 두면 두 번째 줄이 첫 번째를 조용히
## 없앤다 — 목록에는 이름이 그대로 있어서 `missing()` 도 초록이다.
func test_a_duplicate_name_is_refused_and_the_first_one_stays() -> void:
	var c := Claim.new()
	c.add(Claim.BODY, func(tile: Vector2i) -> bool: return tile == T)
	check(not c.add(Claim.BODY, func(tile: Vector2i) -> bool: return tile == U), "같은 이름을 두 번 받았다")
	eq(c.count(), 1, "거절한 뒤 꽂힌 출처의 수")
	check(c.covers(T), "먼저 꽂은 출처가 사라졌다")
	check(not c.covers(U), "나중 것이 덮어썼다")

## **빈 이름과 빈 Callable 은 안 받는다.** 둘 다 「꽂았다고 생각하는데 아무도 안 답하는」
## 상태를 만든다 — `count()` 만 오르고 칸은 안 막힌다.
func test_a_nameless_or_empty_source_is_refused() -> void:
	var c := Claim.new()
	check(not c.add(&"", func(tile: Vector2i) -> bool: return true), "빈 이름을 받았다")
	check(not c.add(&"설치물", Callable()), "빈 Callable 을 받았다")
	eq(c.count(), 0, "거절한 뒤 꽂힌 출처의 수")

## ── 선언 ─────────────────────────────────────────────────────────────

## **선언한 종류마다 「왜」가 붙어 있다.** 이름만 늘어난 목록은 다음 회차에게
## 아무것도 안 알려 준다 — 그러면 등록을 빼먹는 이유가 하나 더 생긴다.
func test_every_declared_kind_says_why() -> void:
	for name: StringName in Claim.KINDS:
		check(name != &"", "선언에 빈 이름이 있다")
		check(String(Claim.KINDS[name]).length() >= 10,
			"%s 의 「왜」가 너무 짧다 — 잰 값 %d 자 · 기대 10 자 이상" % [
				name, String(Claim.KINDS[name]).length()])
