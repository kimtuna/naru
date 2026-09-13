extends Node2D

## 화면 뼈대 + 48px 격자 + 플레이어.
## 「숫자가 옳은지는 화면을 봐야 안다」 — 그 화면을 띄우는 자리다.
##
## 격자는 **임시**다 (월드 생성은 P1-4). 걸을 때 칸이 지나가는 것을 눈으로 세려고 그린다 —
## 240px/s 가 5칸/초로 보이는지는 숫자가 아니라 이걸로 확인한다.

const GRID_A := Color(0.15, 0.17, 0.20)
const GRID_B := Color(0.19, 0.22, 0.26)

func _ready() -> void:
	var vis := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	print("VIEWPORT %d x %d" % [int(vis.x), int(vis.y)])
	print("WINDOW   %d x %d" % [win.x, win.y])
	print("SCALE    %.2f x" % (float(win.x) / vis.x))
	print("TILE     %d px · 보이는 칸 %.2f x %.2f" % [
		int(PlayerMotion.TILE), vis.x / PlayerMotion.TILE, vis.y / PlayerMotion.TILE])
	print("SPEED    %d px/s = %.1f 칸/s" % [
		int(PlayerMotion.SPEED), PlayerMotion.SPEED / PlayerMotion.TILE])

func _draw() -> void:
	var t := PlayerMotion.TILE
	var vis := get_viewport().get_visible_rect().size
	var cols := int(ceil(vis.x / t))
	var rows := int(ceil(vis.y / t))
	for y in rows:
		for x in cols:
			var c: Color = GRID_A if (x + y) % 2 == 0 else GRID_B
			draw_rect(Rect2(x * t, y * t, t, t), c)
