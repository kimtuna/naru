class_name CraftingView
extends PanelContainer
## 제작 화면 — 연 제작대에서 만드는 레시피 목록 (spec/05_craft/crafting-stations.md).
## 지금은 열고 닫기와 목록만 있다. 제작 시작 · 타이머 · 출력 버퍼는 다음 단계. 그림은 임시다.
## Esc(menu_exit) · 가방 키로 닫는다 — 열려 있는 동안 그 키는 게임을 나가거나 가방을 열지 않는다.
## 마우스를 가로채지 않는다 — 열려 있는 동안 좌클릭을 막는 것은 Harvester · Stations 가 is_open() 을 보고 한다.

signal toggled(open: bool)

const CLOSE_ACTIONS: Array[StringName] = [&"menu_exit", InputActions.INVENTORY]
const STATION_TR_PREFIX := "STATION_"
const ITEM_TR_PREFIX := "ITEM_"

## 연 제작대. 닫혀 있으면 null.
var station: CraftStation


func _ready() -> void:
	visible = false


func is_open() -> bool:
	return visible


func open_station(target: CraftStation, book: RecipeBook) -> void:
	station = target
	%Title.text = station_key(target.station_id)
	var recipes: Array[Dictionary] = []
	if book:
		recipes = book.recipes_at(target.station_id)
	_fill(recipes)
	if not visible:
		visible = true
		toggled.emit(true)


func close() -> void:
	station = null
	if visible:
		visible = false
		toggled.emit(false)


static func station_key(id: String) -> String:
	return STATION_TR_PREFIX + id.to_upper()


static func item_key(id: String) -> String:
	return ITEM_TR_PREFIX + id.to_upper()


func recipe_list() -> VBoxContainer:
	return %Recipes


## 목록에 보이는 레시피 id 들 (위에서부터).
func shown_recipes() -> PackedStringArray:
	var out := PackedStringArray()
	for child in recipe_list().get_children():
		if not child.is_queued_for_deletion():
			out.append(str(child.get_meta("recipe_id", "")))
	return out


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	for action in CLOSE_ACTIONS:
		if event.is_action_pressed(action) and not event.is_echo():
			get_viewport().set_input_as_handled()
			close()
			return


func _fill(recipes: Array[Dictionary]) -> void:
	for child in recipe_list().get_children():
		recipe_list().remove_child(child)
		child.queue_free()
	for r in recipes:
		var row := Label.new()
		row.name = "Recipe_" + str(r.id)
		row.text = item_key(str(r.output.id))
		row.set_meta("recipe_id", r.id)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		recipe_list().add_child(row)
