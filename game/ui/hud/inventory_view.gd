class_name InventoryView
extends PanelContainer
## 가방 화면 — Inventory 의 칸 목록. InputActions.INVENTORY 로 열고 닫는다 (spec/02_player/inventory-hotbar.md).
## 지금은 칸 목록만 보인다. 옮기기 · 버리기는 나중 단계. 그림은 임시 색 네모다.
## 장비 칸(지금은 신발)을 누르면 비었을 땐 손에 든 것을 끼우고, 찼을 땐 빼서 가방에 넣는다 (Equipment).
## 마우스를 가로채지 않는다 — 열려 있는 동안 좌클릭을 막는 것은 Harvester 가 is_open() 을 보고 한다.

signal toggled(open: bool)

const COLUMNS := 10
const EQUIP_TR_PREFIX := "EQUIP_"

var inventory: Inventory
var equipment: Equipment
## 장비 칸을 누를 때 끼울 아이템 — 이 핫바에서 고른 칸.
var hotbar: Hotbar
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


func bind_equipment(target: Equipment, bar: Hotbar) -> void:
	if equipment and equipment.changed.is_connected(refresh):
		equipment.changed.disconnect(refresh)
	equipment = target
	hotbar = bar
	equipment.changed.connect(refresh)
	_build_equipment()
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


## 장비 칸 버튼 (칸 이름은 EquipmentConfig.SLOTS). 없으면 null.
func equipment_slot(slot_name: String) -> Button:
	return %Equipment.get_node_or_null(_equip_node_name(slot_name)) as Button


func equipment_slot_has_item(slot_name: String) -> bool:
	var button := equipment_slot(slot_name)
	return button != null and ItemSlot.has_item(button.get_node("Item"))


## 장비 칸을 누른 것과 같다 — 찼으면 빼고, 비었으면 손에 든 것을 끼운다. 바뀌었으면 true.
func press_equipment_slot(slot_name: String) -> bool:
	if equipment == null:
		return false
	if equipment.item(slot_name) != null:
		return equipment.unequip(slot_name)
	if hotbar == null or not (hotbar.held_item() is Dictionary):
		return false
	if Equipment.slot_of(str(hotbar.held_item().get("id", ""))) != slot_name:
		return false
	return equipment.equip_from_bag(hotbar.selected() - 1)


func refresh() -> void:
	if inventory == null:
		return
	for i in slot_count():
		ItemSlot.show_item(slot(i), inventory.slot(i))
	if equipment == null:
		return
	for slot_name in EquipmentConfig.SLOTS:
		var button := equipment_slot(slot_name)
		if button:
			ItemSlot.show_item(button.get_node("Item"), equipment.item(slot_name))


func _build_equipment() -> void:
	for child in %Equipment.get_children():
		%Equipment.remove_child(child)
		child.queue_free()
	for slot_name in EquipmentConfig.SLOTS:
		var label := Label.new()
		label.text = EQUIP_TR_PREFIX + slot_name.to_upper()
		%Equipment.add_child(label)
		var button := Button.new()
		button.name = _equip_node_name(slot_name)
		button.custom_minimum_size = ItemSlot.SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_child(ItemSlot.make("Item"))
		button.pressed.connect(press_equipment_slot.bind(slot_name))
		%Equipment.add_child(button)


func _equip_node_name(slot_name: String) -> String:
	return "Equip_" + slot_name


func _build() -> void:
	for child in grid().get_children():
		grid().remove_child(child)
		child.queue_free()
	for i in inventory.size():
		# 핫바 칸에는 숫자키를 적어 둔다.
		var key := str((i + 1) % 10) if i < InventoryConfig.HOTBAR_SIZE else ""
		grid().add_child(ItemSlot.make("Slot%d" % i, key))
