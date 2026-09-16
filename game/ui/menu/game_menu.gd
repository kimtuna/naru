class_name GameMenu
extends Control
## 게임 중 설정 창 (Esc) — 계속하기 · 설정 · 월드 설정(서버장만) · 메인 화면으로 · 게임 종료 (spec/12_ui/menu.md).
## 설정 · 월드 설정은 아직 빈 자리다 — 뒤로 가기만 된다.
## Esc 는 게임 씬이 받아 back() 을 부른다 (가방 · 제작 화면을 먼저 닫아야 해서 한 곳에서 고른다).
## 열려 있는 동안 화면 전체가 마우스를 가로챈다 — 클릭이 게임에 들어가지 않는다. 월드는 멈추지 않는다.

signal toggled(open: bool)
## 「메인 화면으로」 — 게임 씬이 저장하고 나간다.
signal main_menu_requested
## 「게임 종료」 — 게임 씬이 저장하고 끝낸다.
signal quit_requested

const PAGE_MAIN := &"main"
const PAGE_SETTINGS := &"settings"
const PAGE_WORLD_SETTINGS := &"world_settings"

## 서버장인가 — 아니면 월드 설정이 보이지 않는다.
var is_host := true


func _ready() -> void:
	visible = false
	%Continue.pressed.connect(close)
	%Settings.pressed.connect(show_page.bind(PAGE_SETTINGS))
	%WorldSettings.pressed.connect(show_page.bind(PAGE_WORLD_SETTINGS))
	%SettingsBack.pressed.connect(show_page.bind(PAGE_MAIN))
	%WorldSettingsBack.pressed.connect(show_page.bind(PAGE_MAIN))
	%MainMenu.pressed.connect(main_menu_requested.emit)
	%Quit.pressed.connect(quit_requested.emit)
	set_host(is_host)


func is_open() -> bool:
	return visible


func open() -> void:
	show_page(PAGE_MAIN)
	if not visible:
		visible = true
		toggled.emit(true)
	%Continue.grab_focus()


func close() -> void:
	if not visible:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused and is_ancestor_of(focused):
		focused.release_focus()
	visible = false
	toggled.emit(false)


## Esc — 안쪽 화면이면 목록으로, 목록이면 닫는다.
func back() -> void:
	if page() != PAGE_MAIN:
		show_page(PAGE_MAIN)
	else:
		close()


func set_host(host: bool) -> void:
	is_host = host
	%WorldSettings.visible = host
	if not host and page() == PAGE_WORLD_SETTINGS:
		show_page(PAGE_MAIN)


func show_page(name_: StringName) -> void:
	if name_ == PAGE_WORLD_SETTINGS and not is_host:
		return
	%Main.visible = name_ == PAGE_MAIN
	%SettingsPage.visible = name_ == PAGE_SETTINGS
	%WorldSettingsPage.visible = name_ == PAGE_WORLD_SETTINGS
	var first: Button = {PAGE_MAIN: %Continue, PAGE_SETTINGS: %SettingsBack,
		PAGE_WORLD_SETTINGS: %WorldSettingsBack}[name_]
	if visible:
		first.grab_focus()


## 지금 보이는 화면 — PAGE_*.
func page() -> StringName:
	if %SettingsPage.visible:
		return PAGE_SETTINGS
	if %WorldSettingsPage.visible:
		return PAGE_WORLD_SETTINGS
	return PAGE_MAIN


## 이름으로 버튼 — Continue · Settings · WorldSettings · MainMenu · Quit · SettingsBack · WorldSettingsBack.
func button(button_name: String) -> Button:
	return get_node("%" + button_name) as Button
