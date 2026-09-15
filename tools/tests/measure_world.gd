extends MeasurePhase

## **다른 프로세스에서도 같은 씨앗이 같은 월드를 주는지** 잰다 (GDD D-1: 서버 재현성).
##
## 왜 단위 검사로는 부족한가: `test_world_gen.gd` 의 「같은 씨앗 = 같은 월드」는
## **한 프로세스 안에서** 두 번 만들어 비교한다. 정적 변수에 시간을 한 번 섞어 두면
## 그 프로세스 안에서는 늘 같은 값이 나오므로 단위 검사는 전부 초록으로 남고,
## 어제 만든 섬과 오늘 만든 섬만 달라진다. 그 구멍을 여기서 막는다.
##
## **땅 위에 놓인 것도 같이 잰다** (회차 24): 나무·돌·광물의 자리는 지형과 **다른 소금**을
## 쓰는 해시라서, 지형 체크섬이 맞아도 배치만 프로세스마다 달라질 수 있다.
## 그러면 「어제 심은 나무가 오늘 딴 자리」인데 섬은 똑같아서 아무도 못 본다.
##
## 이 파일 자체는 한 번 돌아 값을 찍기만 한다. **비교는 check.sh 가 한다** —
## 두 번 띄워서 `WORLD` 줄이 글자 하나까지 같은지 본다.
##
## 헤드리스로 된다 — 순수 계산이라 창도 렌더러도 필요 없다.
##
## **홀로 도는 프로세스가 아니다** (회차 27): `measure_headless.gd` 의 한 구간이다.
## **이 게이트만은 여전히 두 프로세스가 필요하다** — 「다른 프로세스에서도 같은가」가
## 묻는 것 그 자체라서다. 그래서 check.sh 는 두 번째 프로세스를
## `measure_headless.gd -- world` 로 **이 구간만** 부른다.
##
## **찍는 줄의 머리말이 `main.gd` 와 부딪힌다** (회차 27): 메인 씬은 `_ready` 에서
## `WORLD    씨앗 ...` 를 찍는데, 한 프로세스가 된 뒤로는 COLLIDE·CAMERA 가 메인 씬을
## 세우므로 그 줄이 **같은 출력에 섞인다.** `^WORLD ` 로 긁으면 두 프로세스의 줄 수가
## 달라져서 「씨앗이 프로세스마다 다르다」로 영영 빨개진다 — check.sh 는 그래서
## `^WORLD [0-9]` 로 긁는다 (`measure_window.gd` 의 `WINGATE` 와 같은 자리의 함정이다).

const SEEDS := [1, 42, -20260914]

func tag() -> String:
	return "WORLD"

func step(_delta: float) -> bool:
	var t0 := Time.get_ticks_msec()
	for s in SEEDS:
		var grid := WorldGen.generate(s)
		var objs := WorldObjects.generate(s)
		var k := WorldObjects.counts(objs)
		# **시간은 이 줄에 넣지 않는다** — 실행마다 달라서 비교가 늘 빨개진다.
		print("WORLD %dx%d · 씨앗 %d · 땅 %.2f%% · 체크섬 0x%08x · 나무 %d · 돌 %d · 광물 %d · 놓임 0x%08x" % [
			WorldGen.SIZE, WorldGen.SIZE, s,
			100.0 * WorldGen.land_count(grid) / grid.size(), WorldGen.checksum(grid),
			k[WorldObjects.TREE], k[WorldObjects.ROCK], k[WorldObjects.ORE],
			WorldGen.checksum(objs)])
	print("WORLDGEN %d장(지형+놓임) · %d ms" % [SEEDS.size(), Time.get_ticks_msec() - t0])
	return true
