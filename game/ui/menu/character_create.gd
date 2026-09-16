extends Control
## 캐릭터 생성 — 이름과 외형 항목(데이터 파일 AppearanceCatalog)을 고른다.
## 만들기 → Session.character_slot 칸에 저장하고 캐릭터 선택으로. 취소 → 저장 없이 캐릭터 선택으로.
## 모양 · 배치는 자리만 — 디자인은 사람이 나중에 넣는다.

const PREVIEW_SIZE := Vector2(80, 20)
## 외형 줄의 항목 이름 · 선택지 칸 너비 (기준 화면 640×360 픽셀).
const PART_COLUMN_WIDTH := 80

var catalog: AppearanceCatalog
## 항목 index → 고른 선택지 index.
var _choice: Array[int] = []


func _ready() -> void:
	catalog = AppearanceCatalog.load_default()
	for i in catalog.parts.size():
		_choice.append(0)
		_build_part(i)
	%Create.pressed.connect(create)
	%Cancel.pressed.connect(cancel)
	%NameEdit.text_changed.connect(func(_t): %NameError.hide())
	%NameError.hide()
	%SlotsFull.hide()
	_refresh()
	%NameEdit.grab_focus()


func part_row(part_id: String) -> Control:
	return %Parts.get_node_or_null(part_id) as Control


func preview_rect(part_id: String) -> ColorRect:
	return %Preview.get_node_or_null(part_id) as ColorRect


## 항목 index 의 선택지를 step 만큼 옮긴다 (끝에서 돌아간다).
func step(part_index: int, delta: int) -> void:
	_choice[part_index] = posmod(_choice[part_index] + delta, catalog.option_count(part_index))
	_refresh()


## 지금 고른 외형 {항목 id: 선택지 id}.
func appearance() -> Dictionary:
	var out := {}
	for i in catalog.parts.size():
		out[catalog.parts[i].id] = catalog.parts[i].options[_choice[i]].id
	return out


func create() -> void:
	var char_name: String = %NameEdit.text.strip_edges()
	if char_name.is_empty():
		%NameError.show()
		return
	var data := CharacterData.new()
	data.name = char_name
	data.appearance = appearance()
	var slot := Session.character_slot
	var ok := false
	if slot >= 0 and not Session.store.has_character(slot):
		ok = Session.store.save_character(slot, data) == OK
	else:
		# 칸을 고르지 않고 왔거나 그새 찬 칸이면 빈 칸을 찾는다.
		ok = Session.store.create_character(data) >= 0
	if not ok:
		%SlotsFull.show()
		return
	Session.clear()
	Screens.go(self, Screens.CHARACTER_SELECT)


func cancel() -> void:
	Session.clear()
	Screens.go(self, Screens.CHARACTER_SELECT)


func _build_part(i: int) -> void:
	var part: Dictionary = catalog.parts[i]
	var row := HBoxContainer.new()
	row.name = part.id
	var label := Label.new()
	label.name = "Label"
	label.text = part.label
	label.custom_minimum_size.x = PART_COLUMN_WIDTH
	var prev := Button.new()
	prev.name = "Prev"
	prev.text = "APPEARANCE_PREV"
	prev.pressed.connect(step.bind(i, -1))
	var value := Label.new()
	value.name = "Value"
	value.custom_minimum_size.x = PART_COLUMN_WIDTH
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next := Button.new()
	next.name = "Next"
	next.text = "APPEARANCE_NEXT"
	next.pressed.connect(step.bind(i, 1))
	for n in [label, prev, value, next]:
		row.add_child(n)
	%Parts.add_child(row)
	var rect := ColorRect.new()
	rect.name = part.id
	rect.custom_minimum_size = PREVIEW_SIZE
	%Preview.add_child(rect)


func _refresh() -> void:
	for i in catalog.parts.size():
		var part: Dictionary = catalog.parts[i]
		var option: Dictionary = part.options[_choice[i]]
		(part_row(part.id).get_node("Value") as Label).text = option.label
		preview_rect(part.id).color = option.color
