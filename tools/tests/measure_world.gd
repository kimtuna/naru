extends SceneTree

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

const SEEDS := [1, 42, -20260914]

func _initialize() -> void:
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
	quit(0)
