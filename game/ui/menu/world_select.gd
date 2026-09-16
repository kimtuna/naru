extends Control
## 월드 선택 · 생성 — 저장된 월드 목록, 새 월드(이름 · 시드), 삭제(확인 한 번), 뒤로 → 캐릭터 선택.
## 월드를 고르면 Session 의 캐릭터와 그 월드를 들고 게임 씬으로 간다.

## 삭제 확인 중인 월드 id. 없으면 "".
var _pending_delete := ""


func _ready() -> void:
	%Back.pressed.connect(back)
	%Create.pressed.connect(create)
	%ConfirmYes.pressed.connect(_confirm_delete)
	%ConfirmNo.pressed.connect(_close_confirm)
	%NameEdit.text_changed.connect(func(_t): %NameError.hide())
	%NameError.hide()
	%CreateFailed.hide()
	%Confirm.hide()
	refresh()
	%NameEdit.grab_focus()


## 목록 순서대로 월드 id.
func listed_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for row in %Worlds.get_children():
		out.append(String(row.get_meta("world_id")))
	return out


func world_button(id: String) -> Button:
	var row := _row(id)
	return row.get_node("Select") as Button if row else null


func delete_button(id: String) -> Button:
	var row := _row(id)
	return row.get_node("Delete") as Button if row else null


## 저장소에서 다시 읽어 목록을 채운다.
func refresh() -> void:
	for row in %Worlds.get_children():
		%Worlds.remove_child(row)
		row.queue_free()
	for id in Session.store.world_ids():
		var data := Session.store.load_world(id)
		if data:
			_build_row(id, data)
	%Empty.visible = %Worlds.get_child_count() == 0


## 입력칸의 이름 · 시드로 새 월드를 만든다. 시드가 비면 무작위. 만든 id, 실패하면 "".
func create() -> String:
	var world_name: String = %NameEdit.text.strip_edges()
	if world_name.is_empty():
		%NameError.show()
		return ""
	var data := WorldData.create(world_name, seed_from_text(%SeedEdit.text))
	var id := Session.store.create_world(data)
	%CreateFailed.visible = id.is_empty()
	if id.is_empty():
		return ""
	%NameEdit.clear()
	%SeedEdit.clear()
	refresh()
	return id


## 시드 칸 글자 → 시드. 비면 무작위, 정수면 그 값, 그 밖의 글자는 글자의 해시 (같은 글자 = 같은 시드).
static func seed_from_text(text: String) -> int:
	var t := text.strip_edges()
	if t.is_empty():
		return randi()
	if t.is_valid_int():
		return t.to_int()
	return t.hash()


func back() -> void:
	Session.clear_world()
	Screens.go(self, Screens.CHARACTER_SELECT)


func _row(id: String) -> Control:
	for row in %Worlds.get_children():
		if row.get_meta("world_id") == id:
			return row
	return null


func _build_row(id: String, data: WorldData) -> void:
	var row := HBoxContainer.new()
	row.name = "World_%d" % %Worlds.get_child_count()
	row.set_meta("world_id", id)
	var select := Button.new()
	select.name = "Select"
	# 월드 이름은 사용자가 쓴 글자라 번역하지 않는다.
	select.text = data.name
	select.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	select.custom_minimum_size.x = 200
	select.pressed.connect(_on_world_pressed.bind(id))
	var delete := Button.new()
	delete.name = "Delete"
	delete.text = "WORLD_DELETE"
	delete.pressed.connect(_ask_delete.bind(id))
	row.add_child(select)
	row.add_child(delete)
	%Worlds.add_child(row)


func _on_world_pressed(id: String) -> void:
	if Session.character == null:
		# 캐릭터 없이 들어올 수 없다 — 캐릭터부터 고른다.
		Screens.go(self, Screens.CHARACTER_SELECT)
		return
	Session.select_world(id)
	if Session.ready_to_play():
		Screens.go(self, Screens.GAME)
	else:
		refresh()


func _ask_delete(id: String) -> void:
	if not Session.store.has_world(id):
		return
	_pending_delete = id
	%Confirm.show()
	%ConfirmNo.grab_focus()


func _confirm_delete() -> void:
	if not _pending_delete.is_empty():
		Session.store.delete_world(_pending_delete)
		if Session.world_id == _pending_delete:
			Session.clear_world()
	_close_confirm()
	refresh()


func _close_confirm() -> void:
	_pending_delete = ""
	%Confirm.hide()
