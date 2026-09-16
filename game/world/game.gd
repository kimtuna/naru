class_name GameScene
extends Node2D
## 게임 씬 — 지금은 빈 자리 (다음 묶음들이 채운다).
## Session 이 들고 온 캐릭터와 월드를 받아 두고, menu_exit 액션으로 둘을 저장한 뒤 메인 화면으로 나간다.

const EXIT_ACTION := "menu_exit"

var character: CharacterData
var world: WorldData


func _ready() -> void:
	character = Session.character
	world = Session.world
	%CharacterName.text = character_name()
	%WorldName.text = world_name()


func character_name() -> String:
	return character.name if character else ""


func world_name() -> String:
	return world.name if world else ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(EXIT_ACTION):
		get_viewport().set_input_as_handled()
		exit_to_menu()


## 캐릭터와 월드를 저장하고 메인 화면으로 나간다.
func exit_to_menu() -> void:
	Session.save_all()
	Session.clear()
	Screens.go(self, Screens.MAIN_MENU)
