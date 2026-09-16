class_name ItemSlot
## 아이템 칸 네모 하나 — 핫바와 가방 화면이 같이 쓴다. 그림은 임시 색 네모다. 아트는 사람이 나중에 넣는다.
## 노드: Background · Icon(아이템이 있을 때만 보임) · Frame(고른 칸 테두리) · Key(숫자키) · Count(2개 이상일 때 개수).

const SIZE := Vector2(40, 40)
const FRAME_COLOR := Color(1, 1, 1, 1)
const EMPTY_COLOR := Color(0, 0, 0, 0.5)


## key_text 는 칸에 적을 숫자키 — 글자가 아니라 키 숫자라 번역하지 않는다. 비우면 적지 않는다.
static func make(node_name: String, key_text := "") -> Control:
	var box := Panel.new()
	box.name = node_name
	box.custom_minimum_size = SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = EMPTY_COLOR
	_fill(bg, 0)
	box.add_child(bg)

	var icon := ColorRect.new()
	icon.name = "Icon"
	icon.visible = false
	_fill(icon, 8)
	box.add_child(icon)

	var frame := ReferenceRect.new()
	frame.name = "Frame"
	frame.editor_only = false
	frame.border_color = FRAME_COLOR
	frame.border_width = 3.0
	frame.visible = false
	_fill(frame, 0)
	box.add_child(frame)

	if not key_text.is_empty():
		var key := Label.new()
		key.name = "Key"
		key.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		key.text = key_text
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


## 칸에 아이템(없으면 null)을 보인다.
static func show_item(box: Control, it: Variant, selected := false) -> void:
	var icon := box.get_node("Icon") as ColorRect
	var count := box.get_node("Count") as Label
	icon.visible = it != null
	count.text = ""
	if it is Dictionary:
		icon.color = item_color(str(it.get("id", "")))
		var c := int(it.get("count", 1))
		count.text = str(c) if c > 1 else ""
	(box.get_node("Frame") as CanvasItem).visible = selected


static func has_item(box: Control) -> bool:
	return (box.get_node("Icon") as CanvasItem).visible


static func count_text(box: Control) -> String:
	return (box.get_node("Count") as Label).text


## 아이템 그림이 생기기 전 임시 — 이름마다 다른 색.
static func item_color(id: String) -> Color:
	return Color.from_hsv(float(absi(hash(id)) % 360) / 360.0, 0.6, 0.9)


static func _fill(c: Control, margin: float) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = margin
	c.offset_top = margin
	c.offset_right = -margin
	c.offset_bottom = -margin
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
