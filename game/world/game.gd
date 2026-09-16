class_name GameScene
extends Node2D
## 게임 씬 — 땅과 플레이어 캐릭터 · 화면 아래 핫바 (나머지는 다음 묶음들이 채운다).
## Session 이 들고 온 캐릭터와 월드를 받아 두고, menu_exit 액션으로 둘을 저장한 뒤 메인 화면으로 나간다.

const EXIT_ACTION := "menu_exit"

var character: CharacterData
var world: WorldData
## 월드를 만들 때 정한 시드로 만든 섬. 월드가 없으면 null.
var island: IslandMap


func _ready() -> void:
	character = Session.character
	world = Session.world
	if world:
		island = IslandGenerator.generate(world.world_seed)
	%CharacterName.text = character_name()
	%WorldName.text = world_name()
	if character:
		player().hotbar = Hotbar.new(character)
	%Hotbar.bind(player().hotbar)


func character_name() -> String:
	return character.name if character else ""


func world_name() -> String:
	return world.name if world else ""


func player() -> Player:
	return %Player


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
