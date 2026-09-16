extends GutTest
## G-010 2단계 화면 테스트가 함께 쓰는 준비 — 임시 저장 폴더 · 기준 창 크기 · 로케일 원복,
## 캐릭터 · 월드 만들기, 화면 열기, 게임 들어가기.
## 파일 이름이 test_ 로 시작하지 않아 혼자서는 돌지 않는다.

const GAME := "res://world/game.tscn"
const SCREEN := Rect2(Vector2.ZERO, Vector2(DisplayConfig.BASE_SIZE))
## 사용자가 쓸 수 있는 가장 긴 이름 (월드 이름 입력칸의 max_length) — 넓은 글자로 채운다.
const LONG_NAME := "WWWWWWWWWWWWWWWWWWWWWWWW"

var _root := ""
var _saved_size := Vector2i.ZERO
var _saved_locale := ""


func before_each() -> void:
	_root = OS.get_temp_dir().path_join("naru_test_fit_%d_%d" % [Time.get_ticks_usec(), randi()])
	Session.store = SaveStore.new(_root)
	Session.clear()
	Screens.simulate = true
	_saved_size = get_tree().root.size
	_saved_locale = TranslationServer.get_locale()
	get_tree().root.size = DisplayConfig.WINDOW_SIZE


func after_each() -> void:
	TranslationServer.set_locale(_saved_locale)
	get_tree().root.size = _saved_size
	Screens.simulate = false
	Session.store = SaveStore.new()
	Session.clear()
	_remove_tree(_root)


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for dir in DirAccess.get_directories_at(path):
		_remove_tree(path.path_join(dir))
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file))
	DirAccess.remove_absolute(path)


func _character(slot: int, char_name: String) -> void:
	var c := CharacterData.new()
	c.name = char_name
	assert_eq(Session.store.save_character(slot, c), OK)


func _open(path: String) -> Control:
	return add_child_autofree((load(path) as PackedScene).instantiate())


func _enter() -> GameScene:
	_character(0, LONG_NAME)
	var id := Session.store.create_world(WorldData.create(LONG_NAME, 20260917))
	Session.select_character(0)
	Session.select_world(id)
	return add_child_autofree((load(GAME) as PackedScene).instantiate())


func _fill_bag(game: GameScene) -> void:
	var inv := game.player().hotbar.inventory
	for i in InventoryConfig.BAG_SIZE:
		inv.set_slot(i, {"id": "stone", "count": InventoryConfig.STACK_MAX})
