class_name CraftingView
extends PanelContainer
## 제작 화면 — 연 제작대에서 만드는 레시피 목록 (spec/05_craft/crafting-stations.md).
## 레시피 버튼을 누르면 제작을 시작하고, 진행 · 출력 버퍼를 보여 주고, 수령 버튼으로 버퍼를 가방에 옮긴다. 그림은 임시다.
## Esc(menu_exit) · 가방 키로 닫는다 — 열려 있는 동안 그 키는 게임을 나가거나 가방을 열지 않는다.
## 버튼 밖 클릭은 가로채지 않는다 — 열려 있는 동안 막는 것은 Swinger · Interactor 가 is_open() 을 보고 한다.
## 버튼은 키보드 포커스를 잡지 않는다 (게임 키를 빼앗지 않게).

signal toggled(open: bool)

const CLOSE_ACTIONS: Array[StringName] = [&"menu_exit", InputActions.INVENTORY]
const STATION_TR_PREFIX := "STATION_"
const ITEM_TR_PREFIX := "ITEM_"

## 연 제작대. 닫혀 있으면 null.
var station: CraftStation
## 재료를 쓰고 결과물을 받는 가방.
var inventory: Inventory
var _book: RecipeBook


func _ready() -> void:
	visible = false
	%Collect.pressed.connect(collect)


func is_open() -> bool:
	return visible


func _process(_delta: float) -> void:
	if visible:
		_refresh()


func bind(target: Inventory) -> void:
	inventory = target


func open_station(target: CraftStation, book: RecipeBook) -> void:
	station = target
	_book = book
	%Title.text = station_key(target.station_id)
	var recipes: Array[Dictionary] = []
	if book:
		recipes = book.recipes_at(target.station_id)
	_fill(recipes)
	_refresh()
	if not visible:
		visible = true
		toggled.emit(true)


## 연 제작대에서 이 레시피를 시작한다 (레시피 버튼).
func start_recipe(recipe_id: String) -> bool:
	if station == null or _book == null:
		return false
	var ok := station.start(_book.get_recipe(recipe_id), inventory)
	_refresh()
	return ok


## 연 제작대의 버퍼를 가방으로 옮긴다 (수령 버튼). 옮긴 개수.
func collect() -> int:
	if station == null:
		return 0
	var moved := station.collect(inventory)
	_refresh()
	return moved


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


func recipe_button(recipe_id: String) -> Button:
	return recipe_list().get_node_or_null("Recipe_" + recipe_id) as Button


func _fill(recipes: Array[Dictionary]) -> void:
	_clear(recipe_list())
	for r in recipes:
		var row := Button.new()
		row.name = "Recipe_" + str(r.id)
		row.text = item_key(str(r.output.id))
		row.set_meta("recipe_id", r.id)
		row.focus_mode = Control.FOCUS_NONE
		row.pressed.connect(start_recipe.bind(str(r.id)))
		recipe_list().add_child(row)


## 진행 · 버퍼 · 버튼 상태를 제작대에 맞춘다.
func _refresh() -> void:
	if station == null:
		return
	var busy := station.is_busy()
	%Status.text = tr("CRAFT_PROGRESS") % [tr(item_key(str(station.job.output.id))), ceili(station.time_left())] \
		if busy else tr("CRAFT_IDLE")
	for row in recipe_list().get_children():
		if row is Button:
			row.disabled = busy or inventory == null or _book == null \
				or not _book.has_materials(_book.get_recipe(str(row.get_meta("recipe_id", ""))), inventory)
	%Collect.disabled = station.buffer.is_empty()
	var shown := station.buffer.map(func(it): return "%s:%d" % [it.id, it.count])
	if %Buffer.get_meta("shown", []) == shown:
		return
	%Buffer.set_meta("shown", shown)
	_clear(%Buffer)
	for it in station.buffer:
		var line := Label.new()
		line.text = tr("CRAFT_BUFFER_ITEM") % [tr(item_key(str(it.id))), it.count]
		line.set_meta("item", it.duplicate())
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		%Buffer.add_child(line)


## 버퍼에 보이는 줄들 — [{"id", "count"}].
func shown_buffer() -> Array:
	var out := []
	for child in %Buffer.get_children():
		if not child.is_queued_for_deletion():
			out.append(child.get_meta("item"))
	return out


func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
