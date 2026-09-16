class_name HotbarView
extends HBoxContainer
## 화면 아래 핫바 — Hotbar 의 칸마다 네모 하나. 고른 칸은 테두리로 구분한다 (spec/12_ui/hud.md).
## 그림은 임시 색 네모다. 아트는 사람이 나중에 넣는다.

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
	return ItemSlot.has_item(slot(n))


func refresh() -> void:
	if hotbar == null:
		return
	for n in range(1, slot_count() + 1):
		ItemSlot.show_item(slot(n), hotbar.item(n), n == hotbar.selected())


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for n in range(1, hotbar.size() + 1):
		add_child(ItemSlot.make("Slot%d" % n, str(n % 10)))
