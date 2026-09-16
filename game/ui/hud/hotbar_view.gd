class_name HotbarView
extends HBoxContainer
## 화면 아래 핫바 — Hotbar 의 칸마다 네모 하나. 고른 칸은 테두리로 구분한다 (spec/12_ui/hud.md).
## 그림은 임시 색 네모다. 아트는 사람이 나중에 넣는다.

const SLOT_SIZE := Vector2(40, 40)
const FRAME_COLOR := Color(1, 1, 1, 1)
const EMPTY_COLOR := Color(0, 0, 0, 0.5)

var hotbar: Hotbar


func bind(target: Hotbar) -> void:
	if hotbar and hotbar.changed.is_connected(refresh):
		hotbar.changed.disconnect(refresh)
	hotbar = target
	hotbar.changed.connect(refresh)
	_build()
	refresh()


func slot_count() -> int:
	return get_child_count()


## N번 칸 (1부터) 의 네모.
func slot(n: int) -> Control:
	return get_child(n - 1) as Control


func is_slot_selected(n: int) -> bool:
	return (slot(n).get_node("Frame") as CanvasItem).visible


func slot_has_item(n: int) -> bool:
	return (slot(n).get_node("Icon") as CanvasItem).visible


func refresh() -> void:
	if hotbar == null:
		return
	for n in range(1, slot_count() + 1):
		var box := slot(n)
		var it = hotbar.item(n)
		var icon := box.get_node("Icon") as ColorRect
		var count := box.get_node("Count") as Label
		icon.visible = it != null
		count.text = ""
		if it is Dictionary:
			icon.color = _item_color(str(it.get("id", "")))
			var c := int(it.get("count", 1))
			count.text = str(c) if c > 1 else ""
		(box.get_node("Frame") as CanvasItem).visible = n == hotbar.selected()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for n in range(1, hotbar.size() + 1):
		add_child(_make_slot(n))


func _make_slot(n: int) -> Control:
	var box := Panel.new()
	box.name = "Slot%d" % n
	box.custom_minimum_size = SLOT_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = EMPTY_COLOR
	_fill(bg, 0)
	box.add_child(bg)

	var icon := ColorRect.new()
	icon.name = "Icon"
	_fill(icon, 8)
	box.add_child(icon)

	var frame := ReferenceRect.new()
	frame.name = "Frame"
	frame.editor_only = false
	frame.border_color = FRAME_COLOR
	frame.border_width = 3.0
	_fill(frame, 0)
	box.add_child(frame)

	# 숫자키 표시 — 글자가 아니라 키 숫자라 번역하지 않는다.
	var key := Label.new()
	key.name = "Key"
	key.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	key.text = str(n % 10)
	key.position = Vector2(3, 0)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(key)

	var count := Label.new()
	count.name = "Count"
	count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_fill(count, 2)
	box.add_child(count)
	return box


func _fill(c: Control, margin: float) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = margin
	c.offset_top = margin
	c.offset_right = -margin
	c.offset_bottom = -margin
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 아이템 그림이 생기기 전 임시 — 이름마다 다른 색.
func _item_color(id: String) -> Color:
	return Color.from_hsv(float(absi(hash(id)) % 360) / 360.0, 0.6, 0.9)
