extends Control
## 메인 화면 — 시작 · 설정 · 종료.


func _ready() -> void:
	%Start.pressed.connect(func(): Screens.go(self, Screens.CHARACTER_SELECT))
	%Settings.pressed.connect(func(): Screens.go(self, Screens.SETTINGS))
	%Quit.pressed.connect(func(): Screens.quit(self))
	%Start.grab_focus()
