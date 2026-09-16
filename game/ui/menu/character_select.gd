extends Control
## 캐릭터 선택 — 슬롯 SaveConfig.CHARACTER_SLOTS 개.
## 빈 칸 → 캐릭터 생성, 찬 칸 → 그 캐릭터를 들고 월드 선택. 삭제는 확인을 한 번 거친다.

const EMPTY_TEXT := "CHARACTER_NEW"

## 삭제 확인 중인 슬롯. 없으면 -1.
var _pending_delete := -1


func _ready() -> void:
	for slot in SaveConfig.CHARACTER_SLOTS:
		_build_slot(slot)
	%Back.pressed.connect(func(): Screens.go(self, Screens.MAIN_MENU))
	%ConfirmYes.pressed.connect(_confirm_delete)
	%ConfirmNo.pressed.connect(_close_confirm)
	%Confirm.hide()
	refresh()
	slot_button(0).grab_focus()


func slot_button(slot: int) -> Button:
	return %Slots.get_node("Slot%d/Select" % slot) as Button


func delete_button(slot: int) -> Button:
	return %Slots.get_node("Slot%d/Delete" % slot) as Button


## 저장소에서 다시 읽어 칸을 채운다.
func refresh() -> void:
	for slot in SaveConfig.CHARACTER_SLOTS:
		var data := Session.store.load_character(slot)
		var button := slot_button(slot)
		# 캐릭터 이름은 사용자가 쓴 글자라 번역하지 않는다.
		button.text = data.name if data else EMPTY_TEXT
		button.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED if data else AUTO_TRANSLATE_MODE_ALWAYS
		delete_button(slot).visible = data != null


func _build_slot(slot: int) -> void:
	var row := HBoxContainer.new()
	row.name = "Slot%d" % slot
	var select := Button.new()
	select.name = "Select"
	select.custom_minimum_size.x = 200
	select.pressed.connect(_on_slot_pressed.bind(slot))
	var delete := Button.new()
	delete.name = "Delete"
	delete.text = "CHARACTER_DELETE"
	delete.pressed.connect(_ask_delete.bind(slot))
	row.add_child(select)
	row.add_child(delete)
	%Slots.add_child(row)


func _on_slot_pressed(slot: int) -> void:
	Session.select_character(slot)
	Screens.go(self, Screens.WORLD_SELECT if Session.character else Screens.CHARACTER_CREATE)


func _ask_delete(slot: int) -> void:
	if not Session.store.has_character(slot):
		return
	_pending_delete = slot
	%Confirm.show()
	%ConfirmNo.grab_focus()


func _confirm_delete() -> void:
	if _pending_delete >= 0:
		Session.store.delete_character(_pending_delete)
		if Session.character_slot == _pending_delete:
			Session.clear()
	_close_confirm()
	refresh()


func _close_confirm() -> void:
	_pending_delete = -1
	%Confirm.hide()
