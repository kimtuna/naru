extends SceneTree

## 월드 한 장을 PNG 로 굽는다 — **사람 눈으로 「섬처럼 생겼나」를 보는 자리다.**
##
## 숫자(땅 비율·체크섬)는 상태 검사가 잰다. 그런데 「가장자리가 물이고 비율이 35%」인 월드는
## 도넛일 수도, 점 100개일 수도 있다. 그건 재는 게 아니라 봐야 안다.
##
## 사용법: godot --headless --path . --script res://tools/qa/world_png.gd -- <출력.png> [씨앗]
## 헤드리스로 된다 — Image 는 CPU 쪽이라 렌더러가 필요 없다.

const C_WATER := Color(0.09, 0.20, 0.36)
const C_LAND := Color(0.29, 0.45, 0.24)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/world.png"
	var world_seed: int = int(args[1]) if args.size() > 1 else 1

	var grid := WorldGen.generate(world_seed)
	var img := Image.create(WorldGen.SIZE, WorldGen.SIZE, false, Image.FORMAT_RGB8)
	for y in WorldGen.SIZE:
		for x in WorldGen.SIZE:
			img.set_pixel(x, y, C_LAND if grid[y * WorldGen.SIZE + x] == WorldGen.LAND else C_WATER)

	if img.save_png(out) != OK:
		print("WORLDPNG ERROR 저장 실패: %s" % out)
		quit(1)
		return
	print("WORLDPNG %dx%d · 씨앗 %d · 땅 %.2f%% · 체크섬 0x%08x → %s" % [
		WorldGen.SIZE, WorldGen.SIZE, world_seed,
		100.0 * WorldGen.land_count(grid) / grid.size(), WorldGen.checksum(grid), out])
	quit(0)
