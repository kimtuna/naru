extends GutTest
## G-004 1단계 — 게임 씬은 월드를 만들 때 정한 시드로 섬을 만든다.

const GAME := "res://world/game.tscn"

var _root := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_island_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()


func after_each() -> void:
	Session.store = SaveStore.new()
	Session.clear()
	for dir in [SaveConfig.CHARACTER_DIR, SaveConfig.WORLD_DIR]:
		var p := _root.path_join(dir)
		if DirAccess.dir_exists_absolute(p):
			for f in DirAccess.get_files_at(p):
				DirAccess.remove_absolute(p.path_join(f))
			DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(_root)


func _enter_world(seed_value: int) -> GameScene:
	var c := CharacterData.new()
	c.name = "tester"
	assert_eq(Session.store.save_character(0, c), OK)
	var id := Session.store.create_world(WorldData.create("island", seed_value))
	Session.select_character(0)
	# 저장했다가 다시 읽은 월드로 들어간다 — 저장된 시드가 쓰인다.
	Session.select_world(id)
	return add_child_autofree((load(GAME) as PackedScene).instantiate())


func test_game_builds_island_from_world_seed() -> void:
	var game := _enter_world(8675309)
	assert_not_null(game.island)
	assert_eq(game.island.world_seed, 8675309)
	var expected := IslandGenerator.generate(8675309)
	assert_eq(game.island.deposit_bytes(), expected.deposit_bytes())
	assert_eq(game.island.terrain_bytes(), expected.terrain_bytes())


func test_seed_typed_at_world_creation_is_used() -> void:
	# 월드 선택 화면의 시드 칸 → 저장 → 게임 씬까지 같은 시드.
	var seed_value := _seed_from_menu("my island")
	var game := _enter_world(seed_value)
	assert_eq(game.island.world_seed, "my island".hash())
	var other := IslandGenerator.generate(seed_value + 1)
	assert_ne(game.island.deposit_bytes(), other.deposit_bytes())


func _seed_from_menu(text: String) -> int:
	var script: GDScript = load("res://ui/menu/world_select.gd")
	return script.seed_from_text(text)
