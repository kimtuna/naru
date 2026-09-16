class_name DeathChestView
extends PanelContainer
## 데스 상자 창 — 담긴 아이템 · 남은 시간 · 모두 꺼내기 (spec/08_combat/damage-death.md). 그림은 임시다.
## 열려 있는 동안 상자의 타이머가 멈춘다 (DeathChest.set_viewing). 상자가 사라지면 닫힌다.
## 가방 키로 닫는다. Esc 로 닫는 것은 게임 씬이 한다 (GameScene.on_escape).
## 버튼 밖 클릭은 가로채지 않는다. 버튼은 키보드 포커스를 잡지 않는다.

signal toggled(open: bool)

const CLOSE_ACTIONS: Array[StringName] = [InputActions.INVENTORY]
const COLUMNS := 10

## 연 상자. 닫혀 있으면 null.
var chest: DeathChest
## 꺼낸 것을 받는 가방.
var inventory: Inventory
## 연 캐릭터의 id — 꺼낼 때 상자가 주인인지 다시 본다.
var who_id := ""


func _ready() -> void:
	visible = false
	%Grid.columns = COLUMNS
	%TakeAll.pressed.connect(take_all)
	for i in InventoryConfig.BAG_SIZE:
		%Grid.add_child(ItemSlot.make("Slot%d" % i))


func is_open() -> bool:
	return visible


func open_chest(target: DeathChest, bag: Inventory, opener_id: String) -> void:
	if chest != target:
		_release()
		chest = target
		chest.set_viewing(true)
		chest.changed.connect(refresh)
		chest.emptied.connect(close)
		chest.expired.connect(close)
	inventory = bag
	who_id = opener_id
	refresh()
	if not visible:
		visible = true
		toggled.emit(true)


## 모두 꺼내기 버튼. 옮긴 개수.
func take_all() -> int:
	if chest == null:
		return 0
	var moved := chest.take_all(who_id, inventory)
	refresh()
	return moved


func close() -> void:
	_release()
	if visible:
		visible = false
		toggled.emit(false)


func _release() -> void:
	if chest == null:
		return
	if is_instance_valid(chest):
		chest.set_viewing(false)
		chest.changed.disconnect(refresh)
		chest.emptied.disconnect(close)
		chest.expired.disconnect(close)
	chest = null


func _process(_delta: float) -> void:
	if visible and chest:
		%Time.text = tr("DEATH_CHEST_TIME") % [floori(chest.time_left / 60.0), int(chest.time_left) % 60]


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	for action in CLOSE_ACTIONS:
		if event.is_action_pressed(action) and not event.is_echo():
			get_viewport().set_input_as_handled()
			close()
			return


func slot_count() -> int:
	return %Grid.get_child_count()


func slot_has_item(i: int) -> bool:
	return ItemSlot.has_item(%Grid.get_child(i))


func take_all_button() -> Button:
	return %TakeAll


func refresh() -> void:
	if chest == null:
		return
	for i in slot_count():
		ItemSlot.show_item(%Grid.get_child(i), chest.items[i] if i < chest.items.size() else null)
	%TakeAll.disabled = chest.items.is_empty()
	_process(0.0)
