extends Control
## 설정 화면 — 항목은 아직 미정 (spec/12_ui/menu.md). 뒤로 가기만 된다 (버튼 · Esc).


func _ready() -> void:
	%Back.pressed.connect(back)
	%Back.grab_focus()


func back() -> void:
	Screens.go(self, Screens.MAIN_MENU)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.MENU_EXIT) and not event.is_echo():
		get_viewport().set_input_as_handled()
		back()
