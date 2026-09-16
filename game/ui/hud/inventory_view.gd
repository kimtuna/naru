class_name InventoryView
extends PanelContainer
## 가방 화면 — Inventory 의 칸 목록. InputActions.INVENTORY 로 열고 닫는다 (spec/02_player/inventory-hotbar.md).
## 지금은 칸 목록만 보인다. 옮기기 · 버리기는 나중 단계. 그림은 임시 색 네모다.
## 마우스를 가로채지 않는다 — 열려 있는 동안 좌클릭을 막는 것은 Harvester 가 is_open() 을 보고 한다.

signal toggled(open: bool)

const COLUMNS := 10

var inventory: Inventory
## 참을 돌려주는 동안(설정 창이 열려 있는 동안) 가방 키로 열지 않는다. 게임 씬이 채운다.
var blocked := Callable()


func _ready() -> void:
	visible = false
	%Grid.columns = COLUMNS


func bind(target: Inventory) -> void:
	if inventory and inventory.changed.is_connected(refresh):
		inventory.changed.disconnect(refresh)
	inventory = target
	inventory.changed.connect(refresh)
	_build()
	refresh()


func is_open() -> bool:
	return visible


func set_open(open: bool) -> void:
	if visible == open:
		return
	visible = open
	if open:
		refresh()
	toggled.emit(open)


func toggle() -> void:
	set_open(not visible)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.INVENTORY) and not event.is_echo() \
			and not (blocked.is_valid() and blocked.call()):
		get_viewport().set_input_as_handled()
		toggle()


func grid() -> GridContainer:
	return %Grid


func slot_count() -> int:
	return grid().get_child_count()


## i번 칸 (0부터, Inventory 와 같은 번호) 의 네모.
func slot(i: int) -> Control:
	return grid().get_child(i) as Control


func slot_has_item(i: int) -> bool:
	return ItemSlot.has_item(slot(i))


func slot_count_text(i: int) -> String:
	return ItemSlot.count_text(slot(i))


func refresh() -> void:
	if inventory == null:
		return
	for i in slot_count():
		ItemSlot.show_item(slot(i), inventory.slot(i))


func _build() -> void:
	for child in grid().get_children():
		grid().remove_child(child)
		child.queue_free()
	for i in inventory.size():
		# 핫바 칸에는 숫자키를 적어 둔다.
		var key := str((i + 1) % 10) if i < InventoryConfig.HOTBAR_SIZE else ""
		grid().add_child(ItemSlot.make("Slot%d" % i, key))
