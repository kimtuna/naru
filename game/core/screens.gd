class_name Screens
extends RefCounted
## 게임 밖 화면(메뉴) 사이를 오간다. 화면 경로는 여기 한 곳에 모은다.
## 테스트는 simulate = true 로 두고 last_request 로 요청만 확인한다 (실제 전환 · 종료 없음).

const MAIN_MENU := "res://ui/menu/main_menu.tscn"
const CHARACTER_SELECT := "res://ui/menu/character_select.tscn"
const SETTINGS := "res://ui/menu/settings.tscn"
const CHARACTER_CREATE := "res://ui/menu/character_create.tscn"
const WORLD_SELECT := "res://ui/menu/world_select.tscn"
## 게임 씬 — 지금은 빈 자리 (다음 묶음들이 채운다).
const GAME := "res://world/game.tscn"
const QUIT := "quit"

static var simulate := false
static var last_request := ""


static func go(from: Node, path: String) -> void:
	last_request = path
	if not simulate:
		from.get_tree().change_scene_to_file(path)


static func quit(from: Node) -> void:
	last_request = QUIT
	if not simulate:
		from.get_tree().quit()
