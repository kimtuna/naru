class_name GameScene
extends Node2D
## 게임 씬 — 섬과 플레이어 캐릭터 · 화면 아래 핫바 (나머지는 다음 묶음들이 채운다).
## Session 이 들고 온 캐릭터와 월드를 받아 두고, menu_exit 액션으로 둘을 저장한 뒤 메인 화면으로 나간다.

const EXIT_ACTION := "menu_exit"

var character: CharacterData
var world: WorldData
## 월드를 만들 때 정한 시드로 만든 섬. 월드가 없으면 null.
## 보이는 곳 둘레만 먼저 만든다 — 256×256 이어도 들어가는 시간이 짧다.
var island: IslandMap
## 들어가는 데 걸린 시간 (마이크로초) — _ready 시작부터 섬을 그릴 때까지.
var load_usec := 0


func _ready() -> void:
	var started := Time.get_ticks_usec()
	character = Session.character
	world = Session.world
	if world:
		island = IslandMap.new(IslandGenerator.new(world.world_seed), true)
		island_view().setup(island)
		island_view().follow = player()
		player().global_position = island_view().cell_center(island.spawn())
		island_view().update_around(player().global_position)
	%CharacterName.text = character_name()
	%WorldName.text = world_name()
	if character:
		player().hotbar = Hotbar.new(character)
	%Hotbar.bind(player().hotbar)
	load_usec = Time.get_ticks_usec() - started


func character_name() -> String:
	return character.name if character else ""


func world_name() -> String:
	return world.name if world else ""


func player() -> Player:
	return %Player


func island_view() -> IslandView:
	return %Island


func hotbar_view() -> HotbarView:
	return %Hotbar


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(EXIT_ACTION):
		get_viewport().set_input_as_handled()
		exit_to_menu()


## 캐릭터와 월드를 저장하고 메인 화면으로 나간다.
func exit_to_menu() -> void:
	Session.save_all()
	Session.clear()
	Screens.go(self, Screens.MAIN_MENU)
