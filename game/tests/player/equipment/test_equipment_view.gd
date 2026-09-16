extends GutTest
## G-014 1단계 — 가방 화면의 신발 칸: 손에 든 스파이크를 눌러 끼우고, 다시 눌러 뺀다.

const FEET := EquipmentConfig.FEET
const SPIKES := EquipmentConfig.SPIKES

var view: InventoryView
var bar: Hotbar
var eq: Equipment


func before_each() -> void:
	view = load("res://ui/hud/inventory_view.tscn").instantiate()
	add_child_autofree(view)
	var c := CharacterData.new()
	c.inventory = [{"id": "wood", "count": 1}, {"id": SPIKES, "count": 1}]
	bar = Hotbar.new(c)
	eq = Equipment.new(bar.inventory)
	view.bind(bar.inventory)
	view.bind_equipment(eq, bar)


func test_feet_slot_is_shown_and_labelled() -> void:
	var button := view.equipment_slot(FEET)
	assert_not_null(button, "feet slot button")
	assert_eq(button.focus_mode, Control.FOCUS_NONE, "must not steal game keys")
	var labels := view.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_has(labels, "EQUIP_FEET", "feet slot label uses translation key")
	assert_false(view.equipment_slot_has_item(FEET))


func test_pressing_feet_slot_equips_held_spikes_then_unequips() -> void:
	bar.select(2)
	view.equipment_slot(FEET).pressed.emit()
	assert_true(eq.is_wearing(SPIKES))
	assert_true(view.equipment_slot_has_item(FEET))
	assert_false(view.slot_has_item(1), "bag slot emptied")
	view.equipment_slot(FEET).pressed.emit()
	assert_false(eq.is_wearing(SPIKES))
	assert_false(view.equipment_slot_has_item(FEET))
	assert_eq(bar.inventory.count_of(SPIKES), 1)


func test_pressing_with_wrong_item_does_nothing() -> void:
	bar.select(1)
	assert_false(view.press_equipment_slot(FEET))
	assert_null(eq.item(FEET))
	assert_eq(bar.inventory.count_of("wood"), 1)
