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
## **몇 시에 굽나** (회차 31): `NARU_SHOT_NOW=<게임초>` 를 주면 그 시각에 세우고 굽는다.
## 안 주면 판이 시작하는 시각 — 한낮이다 (`DayCycle.START_PHASE`).
## 이게 없으면 사람이 **밤 화면을 영영 못 본다**: 하루가 20분이라 밤까지 10분을
## 기다려야 하고, 무인 루프에서는 아예 길이 없다.
##
## **가방을 연 채로 굽나** (회차 40): `NARU_SHOT_BAG=1` 이면 창을 열고 굽는다.
## `NARU_SHOT_NOW` 와 같은 이유다 — 없으면 사람이 가방 화면을 눈으로 볼 길이 없다.
## **키를 누르는 게 아니라 창을 연다**: 「E 가 정말 여나」는 게이트(`measure_window.gd`
## 의 BAG)가 키를 눌러 잰다. 여기는 **보여 주는 자리**지 판정하는 자리가 아니다.
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
	var node := packed.instantiate()
	root.add_child(node)

	# **시계를 옮기고 나서 기다린다** — 하늘은 `_process` 가 칠하므로 한 프레임은 돌아야 한다.
	var when := OS.get_environment("NARU_SHOT_NOW")
	if when != "":
		if node.get("world") == null:
			# **조용히 한낮을 굽지 않는다.** 시각을 골랐는데 못 옮겼으면 사람은 그 화면을
			# 「밤이 이렇구나」로 읽는다 — 침묵이 거짓말이 되는 자리다.
			print("SHOT ERROR 이 씬에는 시계가 없다 (NARU_SHOT_NOW=%s)" % when); quit(1); return
		node.world.now = float(when)

	for i in wait_frames:
		await process_frame

	# **가방은 기다린 뒤에 연다** (2026-09-15 실측). 씬의 `_ready` 는 여기 붙인 뒤
	# **첫 프레임에** 돌고 거기서 가방을 닫는다 — 그 전에 열면 조용히 닫힌 화면이 구워진다.
	# 처음엔 그걸 모르고 굽어서 **닫은 PNG 와 바이트까지 같은 파일**이 나왔다.
	# **게임이 쓰는 문으로 연다**(`toggle`): 숨은 `CanvasItem` 은 `queue_redraw` 가
	# 버려지므로 `visible` 만 켜면 빈 창이 뜬다.
	if OS.get_environment("NARU_SHOT_BAG") == "1":
		var bag: BagView = node.get_node_or_null("UI/Bag") as BagView
		if bag == null:
			# 시계와 같은 규칙: **조용히 닫힌 화면을 굽지 않는다.**
			print("SHOT ERROR 이 씬에는 가방이 없다 (NARU_SHOT_BAG=1)"); quit(1); return
		if not bag.is_open():
			bag.toggle()
		await process_frame
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
	# **몇 시에 구웠는지 같이 찍는다** — 안 찍으면 밤 화면과 낮 화면이 파일 이름으로만
	# 갈리고, 시각 옮기기가 조용히 망가져도 아무도 모른다.
	var clock := ""
	var main := root.get_child(root.get_child_count() - 1)
	if main != null and main.get("world") != null:
		var now: float = main.world.now
		clock = "  %.0f s (위상 %.3f · %s · 밝기 %.3f)" % [
			now, DayCycle.phase(now), "낮" if DayCycle.is_day(now) else "밤", DayCycle.daylight(now)]
	print("SHOT %dx%d  색 %d개  가장 넓은 한 색 %.1f%%%s  → %s" % [
		w, h, counts.size(), flat, clock, out])
	quit(0)
