extends GutTest
## G-013 2단계 — 게임 안에서 절벽 · 바다로 걸어 들어가지 못한다.

const GAME := "res://world/game.tscn"
const SEED := 20260916
const Cliffs := preload("res://tests/world/island/test_island_cliffs.gd")

var _root := ""


func after_each() -> void:
	Session.store = SaveStore.new()
	Session.clear()
	if _root != "":
		_remove_dir(_root)
		_root = ""


func _enter() -> GameScene:
	_root = OS.get_temp_dir().path_join("naru_test_cliff_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	var ch := CharacterData.new()
	ch.name = "tester"
	assert_eq(Session.store.save_character(0, ch), OK)
	Session.select_character(0)
	Session.select_world(Session.store.create_world(WorldData.create("island", SEED)))
	return add_child_autofree((load(GAME) as PackedScene).instantiate())


func test_player_cannot_walk_into_cliff_or_sea() -> void:
	var game := _enter()
	var view := game.island_view()
	var dirs := {
		InputActions.MOVE_RIGHT: Vector2i(1, 0), InputActions.MOVE_LEFT: Vector2i(-1, 0),
		InputActions.MOVE_DOWN: Vector2i(0, 1), InputActions.MOVE_UP: Vector2i(0, -1),
	}
	for want_cliff in [true, false]:
		for action in dirs:
			var d: Vector2i = dirs[action]
			var target := Cliffs.approach(game.island, d, want_cliff)
			var label := "%s %s" % ["cliff" if want_cliff else "sea", action]
			assert_ne(target, Vector2i(-1, -1), "no %s to test" % label)
			if target == Vector2i(-1, -1):
				continue
			var p := game.player()
			p.global_position = view.cell_center(target - d * 2)
			p.velocity = Vector2.ZERO
			view.update_around(p.global_position)
			await wait_physics_frames(2)
			var start := p.global_position
			Input.action_press(action)
			await wait_physics_frames(40)
			Input.action_release(action)
			await wait_physics_frames(1)
			var moved := (p.global_position - start).dot(Vector2(d))
			assert_gt(moved, 8.0, "%s: player did not walk" % label)
			assert_ne(view.world_to_cell(p.global_position), target, "%s: walked into it" % label)
			var half := (p.get_node("Shape").shape as RectangleShape2D).size / 2.0
			var lead := (p.global_position + Vector2(d) * half).dot(Vector2(d))
			var face := (view.cell_center(target) - Vector2(d) * (view.tile_px() / 2.0)).dot(Vector2(d))
			assert_lte(lead - face, 0.5, "%s: body crossed the edge" % label)


func _remove_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for d in DirAccess.get_directories_at(path):
		_remove_dir(path.path_join(d))
	for f in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(f))
	DirAccess.remove_absolute(path)
