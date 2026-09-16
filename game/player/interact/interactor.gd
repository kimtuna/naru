class_name Interactor
extends Node
## 우클릭 상호작용 (spec/02_player/movement-controls.md).
## 한 번 누르면 겨눈 칸에 대해 차례로 묻는다:
## 1. 상호작용 오브젝트 (add_object) — 제작대 · 상자처럼 그 칸에 있는 것. 겨눈 곳에 있으면 이쪽이 먼저다
## 2. 손에 든 아이템의 동작 — set_item_action(아이템 id) 이 먼저, 없으면 add_item_handler 에 차례로 묻는다
##    (설치물 → 설치, 뒤에 삽 → 개간 · 씨앗 → 심기 · 음식 → 먹기 가 이 자리를 쓴다)
## 무언가 했으면 입력을 먹는다. 좌클릭(평타)과는 액션이 달라 서로 막지 않는다.

signal interacted(cell: Vector2i)

var player: Player
var view: IslandView
## 참을 돌려주면 우클릭에 반응하지 않는다 (가방 · 제작 화면이 열려 있는 동안). 비워 두면 막지 않는다.
var blocked := Callable()
## func(cell: Vector2i) -> bool — 그 칸의 오브젝트와 상호작용했으면 true.
var _objects: Array[Callable] = []
## 아이템 id → func(item: Dictionary, cell: Vector2i) -> bool
var _item_actions := {}
## func(item: Dictionary, cell: Vector2i) -> bool — 아이템 종류(설치물 등)로 고르는 동작.
var _item_handlers: Array[Callable] = []


func setup(who: Player, island_view: IslandView) -> void:
	player = who
	view = island_view


func add_object(handler: Callable) -> void:
	_objects.append(handler)


## 이 아이템을 들고 우클릭했을 때의 동작.
func set_item_action(item_id: String, action: Callable) -> void:
	_item_actions[item_id] = action


func add_item_handler(handler: Callable) -> void:
	_item_handlers.append(handler)


func is_blocked() -> bool:
	return blocked.is_valid() and blocked.call()


func aimed_cell() -> Vector2i:
	return view.world_to_cell(Pointer.global_position(player))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.INTERACT) or player == null or view == null or is_blocked():
		return
	if interact(aimed_cell()):
		get_viewport().set_input_as_handled()


## 이 칸에 우클릭 한 번 — 무언가 했으면 true.
func interact(cell: Vector2i) -> bool:
	var done := _try_objects(cell) or _try_item(cell)
	if done:
		interacted.emit(cell)
	return done


func _try_objects(cell: Vector2i) -> bool:
	for handler in _objects:
		if handler.is_valid() and handler.call(cell):
			return true
	return false


func _try_item(cell: Vector2i) -> bool:
	var held = player.held_item()
	if not (held is Dictionary):
		return false
	var action: Callable = _item_actions.get(str(held.get("id", "")), Callable())
	if action.is_valid():
		return action.call(held, cell)
	for handler in _item_handlers:
		if handler.is_valid() and handler.call(held, cell):
			return true
	return false
