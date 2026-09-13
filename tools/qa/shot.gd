extends SceneTree

## 게임 화면을 PNG 로 굽는다 — **Godot 자신의 프레임버퍼를 읽는다.**
##
## macOS 의 `screencapture` 는 화면 기록 권한에 막혀서 무인 루프가 못 쓴다
## (2026-09-13 실측: `could not create image from display`).
## 이쪽은 권한이 필요 없고, **화면에 보이는 것이 아니라 게임이 그린 것**을 읽으므로
## 다른 창이 위에 겹쳐도 상관없다.
##
## **헤드리스에서는 안 된다** — 렌더러가 더미라 텍스처가 비어 있다.
## 그래서 tools/loop/shot.sh 는 `--headless` 없이 띄운다.
##
## 사용법: godot --path . --script res://tools/qa/shot.gd -- <출력.png> [씬] [대기프레임]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/shot.png"
	var scene: String = args[1] if args.size() > 1 else "res://scenes/main.tscn"
	var wait_frames: int = int(args[2]) if args.size() > 2 else 10

	var packed: PackedScene = load(scene)
	if packed == null:
		print("SHOT ERROR 씬을 못 연다: %s" % scene); quit(1); return
	root.add_child(packed.instantiate())

	for i in wait_frames:
		await process_frame
	await RenderingServer.frame_post_draw

	var tex: ViewportTexture = root.get_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img == null or img.get_width() == 0:
		print("SHOT ERROR 텍스처가 비었다 (--headless 로 띄웠나?)"); quit(1); return

	if img.save_png(out) != OK:
		print("SHOT ERROR 저장 실패: %s" % out); quit(1); return

	# 잰 값을 찍는다 — 「저장됨」은 증거가 아니다.
	var counts := {}
	var w := img.get_width()
	var h := img.get_height()
	var step: int = maxi(1, w / 240)          # 표본. 전수는 느리다
	var n := 0
	for y in range(0, h, step):
		for x in range(0, w, step):
			var c := img.get_pixel(x, y).to_html(false)
			counts[c] = int(counts.get(c, 0)) + 1
			n += 1
	var top := 0
	for k in counts:
		top = maxi(top, int(counts[k]))
	var flat := float(top) / float(n) * 100.0
	print("SHOT %dx%d  색 %d개  가장 넓은 한 색 %.1f%%  → %s" % [w, h, counts.size(), flat, out])
	quit(0)
