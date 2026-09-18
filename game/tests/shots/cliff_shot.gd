extends Node
## harness/shot.sh 용 — 시드 섬의 게임 화면을 절벽 앞면이 보이는 곳에서 연다 (G-015 3/4 시점 시험).
## 저장은 임시 폴더에 한다. 찍은 시드 · 칸은 print 로 남긴다.

const SEED := 20260916
const GAME := "res://world/game.tscn"


func _ready() -> void:
	var root := OS.get_temp_dir().path_join("naru_shot_%d" % Time.get_ticks_usec())
	Session.store = SaveStore.new(root)
	Session.clear()
	var ch := CharacterData.new()
	ch.name = "shot"
	Session.store.save_character(0, ch)
	Session.select_character(0)
	Session.select_world(Session.store.create_world(WorldData.create("island", SEED)))
	var game: GameScene = (load(GAME) as PackedScene).instantiate()
	add_child(game)
	var cell := _front_near(game.island)
	var at := cell + Vector2i(0, 3)
	game.player().global_position = game.island_view().cell_center(at)
	game.island_view().update_around(game.player().global_position)
	print("shot: seed=%d cliff_front=%s player=%s" % [SEED, cell, at])


## 스폰에서 가까운 줄부터 — 앞면 절벽이 가로로 4칸 넘게 이어진 곳.
func _front_near(map: IslandMap) -> Vector2i:
	var s := map.spawn()
	for r in 80:
		for d in range(-r, r + 1):
			for c in [s + Vector2i(d, -r), s + Vector2i(d, r), s + Vector2i(-r, d), s + Vector2i(r, d)]:
				if _wall(map, c, 4):
					return c
	return s


func _wall(map: IslandMap, c: Vector2i, n: int) -> bool:
	for i in n:
		var p := c + Vector2i(i, 0)
		if not map.has_cell(p) or TileLook.of(map, p) != TileLook.Look.CLIFF_FRONT:
			return false
	return true
