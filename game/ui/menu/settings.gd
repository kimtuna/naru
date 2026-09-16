extends Control
## 설정 화면 — 항목은 아직 미정 (spec/12_ui/menu.md). 뒤로 가기만 된다.


func _ready() -> void:
	%Back.pressed.connect(func(): Screens.go(self, Screens.MAIN_MENU))
	%Back.grab_focus()
