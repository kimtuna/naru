extends Node2D

## P0-1 의 뼈대. 화면에 아무것도 없고, 실제 렌더 크기만 찍는다.
## 「숫자가 옳은지는 화면을 봐야 안다」 — 그 화면을 띄우는 자리다.

func _ready() -> void:
	var vp := get_viewport()
	var vis := vp.get_visible_rect().size
	var win := DisplayServer.window_get_size()
	print("VIEWPORT %d x %d" % [int(vis.x), int(vis.y)])
	print("WINDOW   %d x %d" % [win.x, win.y])
	print("SCALE    %.2f x" % (float(win.x) / vis.x))
