extends Node2D

## 화면 뼈대 + 48px 격자 + 플레이어.
## 「숫자가 옳은지는 화면을 봐야 안다」 — 그 화면을 띄우는 자리다.
##
## **카메라가 플레이어를 따라간다** (P1-6). 카메라는 플레이어 씬 안에 있다 —
## 코드가 매 프레임 따라 붙이는 것이 아니라 **부모-자식이라 공짜로 따라간다.**
## 그래서 바퀴 7 의 `tile_offset` 이 사라졌다: 플레이어는 스폰 칸(128,128)의
## 한가운데에 그냥 서 있고 카메라가 거기를 비춘다. **화면 칸 = 월드 칸**이다.
##
## **줌은 1 이다** (BACKLOG P1): 줌이 곧 시야라서, 1 이 아니면 창이 큰 사람이 더 멀리 본다.
##
## 격자는 아직 **임시**다 — 진짜 타일은 다음 항목에서 그린다.
## 다만 격자는 이제 **월드에 고정**된다. 화면에 고정돼 있으면 카메라가 따라가는지
## 사람 눈에 안 보인다 (플레이어가 격자 위에서 얼어붙은 것처럼 보인다).
## 걸으면 칸이 지나간다 — 240px/s 가 5칸/초로 보이는지는 숫자가 아니라 이걸로 확인한다.

const GRID_A := Color(0.15, 0.17, 0.20)
const GRID_B := Color(0.19, 0.22, 0.26)

## 이 판의 씨앗. 저장·불러오기가 생기면 세이브에서 온다 (GDD D-1).
const WORLD_SEED := 20260914

@onready var _player: Player = $Player

func _ready() -> void:
	_link_world()
	var vis := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	print("VIEWPORT %d x %d" % [int(vis.x), int(vis.y)])
	print("WINDOW   %d x %d" % [win.x, win.y])
	print("SCALE    %.2f x" % (float(win.x) / vis.x))
	print("TILE     %d px · 보이는 칸 %.2f x %.2f" % [
		int(PlayerMotion.TILE), vis.x / PlayerMotion.TILE, vis.y / PlayerMotion.TILE])
	print("SPEED    %d px/s = %.1f 칸/s" % [
		int(PlayerMotion.SPEED), PlayerMotion.SPEED / PlayerMotion.TILE])
	print("WORLD    씨앗 %d · %dx%d 칸 · 스폰 %s · 시작 %s" % [
		WORLD_SEED, WorldGen.SIZE, WorldGen.SIZE, WorldGen.spawn_tile(), _player.position])
	print("CAM      줌 %s · 보이는 월드 %s" % [
		get_viewport().get_canvas_transform().get_scale(), visible_world_rect()])

## 플레이어를 월드에 꽂는다. **이 줄이 없으면 바다 위를 걸어다닌다.**
func _link_world() -> void:
	_player.solid = WorldCollide.solid_from_seed(WORLD_SEED)

## 카메라가 움직이면 보이는 월드 범위가 달라진다 — 격자는 월드에 고정돼 있으므로
## 다시 그려야 한다. 다음 항목의 진짜 타일 그리기도 같은 자리에 얹힌다.
func _process(_delta: float) -> void:
	queue_redraw()

## 지금 화면에 걸리는 월드 범위(픽셀). 카메라의 위치·줌이 전부 여기 들어 있다.
func visible_world_rect() -> Rect2:
	var vp := get_viewport()
	return vp.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, vp.get_visible_rect().size)

func _draw() -> void:
	var t := PlayerMotion.TILE
	var view := visible_world_rect()
	var x0 := floori(view.position.x / t)
	var y0 := floori(view.position.y / t)
	var x1 := floori((view.position.x + view.size.x) / t)
	var y1 := floori((view.position.y + view.size.y) / t)
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			var c: Color = GRID_A if posmod(tx + ty, 2) == 0 else GRID_B
			draw_rect(Rect2(tx * t, ty * t, t, t), c)
