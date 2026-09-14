extends Node2D

## 화면 뼈대 + 48px 격자 + 플레이어.
## 「숫자가 옳은지는 화면을 봐야 안다」 — 그 화면을 띄우는 자리다.
##
## 격자는 아직 **임시**다. 월드(`WorldGen`)는 P1-4 에서 생겼지만 화면에 안 그린다 —
## 섬은 (128,128) 에 있는데 시점은 원점이라 지금 그리면 통째로 바다다.
## **카메라가 플레이어를 따라간 뒤에** 이 격자를 걷어내고 진짜 타일을 그린다 (백로그 P1).
## 그때까지는 걸을 때 칸이 지나가는 것을 눈으로 세는 용도다 —
## 240px/s 가 5칸/초로 보이는지는 숫자가 아니라 이걸로 확인한다.
##
## **월드는 이미 여기 붙어 있다** (P1-5): 플레이어는 진짜 섬의 바다에 못 들어간다.
## 다만 카메라가 없어서(P1-6) 플레이어는 화면 안에 있어야 하고, 섬은 월드 한가운데에 있다 —
## 그래서 **화면 칸을 월드 칸으로 옮기는 `tile_offset`** 을 둔다.
## 플레이어의 시작 칸이 섬의 스폰 칸(128,128)에 겹치도록 맞춘 값이고,
## **카메라가 오면 0 이 되어 사라진다.** 눈에 보이는 격자는 아직 이 지형이 아니다.

const GRID_A := Color(0.15, 0.17, 0.20)
const GRID_B := Color(0.19, 0.22, 0.26)

## 이 판의 씨앗. 저장·불러오기가 생기면 세이브에서 온다 (GDD D-1).
const WORLD_SEED := 20260914

## 화면 칸 + 이 값 = 월드 칸. 카메라(P1-6)가 오면 (0,0) 이 된다.
var tile_offset := Vector2i.ZERO

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
	print("WORLD    씨앗 %d · %dx%d 칸 · 스폰 %s · 화면→월드 %s" % [
		WORLD_SEED, WorldGen.SIZE, WorldGen.SIZE, WorldGen.spawn_tile(), tile_offset])

## 플레이어를 월드에 꽂는다. **이 세 줄이 없으면 바다 위를 걸어다닌다.**
func _link_world() -> void:
	var start := Vector2i(WorldCollide.tile_of(_player.position.x),
			WorldCollide.tile_of(_player.position.y))
	tile_offset = WorldGen.spawn_tile() - start
	_player.solid = WorldCollide.solid_from_seed(WORLD_SEED, tile_offset)

## 월드 칸의 한가운데가 화면 어디인가. 실측 게이트와 다음 바퀴의 그리기가 쓴다.
func screen_of(world_tile: Vector2i) -> Vector2:
	var t := world_tile - tile_offset
	return PlayerMotion.tile_center(t.x, t.y)

func _draw() -> void:
	var t := PlayerMotion.TILE
	var vis := get_viewport().get_visible_rect().size
	var cols := int(ceil(vis.x / t))
	var rows := int(ceil(vis.y / t))
	for y in rows:
		for x in cols:
			var c: Color = GRID_A if (x + y) % 2 == 0 else GRID_B
			draw_rect(Rect2(x * t, y * t, t, t), c)
