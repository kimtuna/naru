extends SceneTree

## **다른 프로세스에서도 같은 씨앗이 같은 월드를 주는지** 잰다 (GDD D-1: 서버 재현성).
##
## 왜 단위 검사로는 부족한가: `test_world_gen.gd` 의 「같은 씨앗 = 같은 월드」는
## **한 프로세스 안에서** 두 번 만들어 비교한다. 정적 변수에 시간을 한 번 섞어 두면
## 그 프로세스 안에서는 늘 같은 값이 나오므로 단위 검사는 전부 초록으로 남고,
## 어제 만든 섬과 오늘 만든 섬만 달라진다. 그 구멍을 여기서 막는다.
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
		# **시간은 이 줄에 넣지 않는다** — 실행마다 달라서 비교가 늘 빨개진다.
		print("WORLD %dx%d · 씨앗 %d · 땅 %.2f%% · 체크섬 0x%08x" % [
			WorldGen.SIZE, WorldGen.SIZE, s,
			100.0 * WorldGen.land_count(grid) / grid.size(), WorldGen.checksum(grid)])
	print("WORLDGEN %d장 · %d ms" % [SEEDS.size(), Time.get_ticks_msec() - t0])
	quit(0)
