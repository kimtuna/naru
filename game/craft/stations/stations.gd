class_name Stations
extends Node2D
## 제작대 설치와 열기 — 좌클릭 하나 규칙 (spec/02_player/movement-controls.md · spec/05_craft/crafting-stations.md).
## - 커서가 손이 닿는 제작대 위면 도구 동작 대신 제작 화면을 연다
## - 아니고 손에 제작대 아이템을 들었으면 겨눈 빈 칸에 설치한다 (막힌 칸 · 닿지 않는 칸은 안 된다)
## 이 둘 중 하나를 하면 입력을 먹어 Harvester 가 휘두르지 않는다 — 트리에서 Harvester 보다 뒤에 있어야 먼저 받는다.
## 손이 닿는 거리는 채취와 같은 값이다 (HarvestConfig.reach_tiles).

signal placed(station: CraftStation)
signal opened(station: CraftStation)

## 비워 두면 harvest_config.tres 를 쓴다 (도달 거리).
@export var config: HarvestConfig

var player: Player
var view: IslandView
## 설치물 둘레에 자원이 다시 자라지 않게 알린다. 비워 두면 알리지 않는다.
var regrowth: Regrowth
## 제작 화면. 비워 두면 열지 않는다.
var craft_view: CraftingView
var book: RecipeBook
## 참을 돌려주면 좌클릭에 반응하지 않는다 (가방 · 제작 화면이 열려 있는 동안).
var blocked := Callable()
## Vector2i → CraftStation
var _by_cell := {}


func _ready() -> void:
	if config == null:
		config = HarvestConfig.load_default()


func setup(who: Player, island_view: IslandView, regrow: Regrowth, crafting: CraftingView,
		recipes: RecipeBook) -> void:
	player = who
	view = island_view
	regrowth = regrow
	craft_view = crafting
	book = recipes


func map() -> IslandMap:
	return view.map if view else null


## 설치할 수 있는 아이템인가 — 맨손(hand)이 아닌 제작 장소 id.
func is_station_item(item_id: String) -> bool:
	return book != null and item_id != RecipeBook.HAND and item_id in book.stations


func station_at(cell: Vector2i) -> CraftStation:
	return _by_cell.get(cell)


func all() -> Array[CraftStation]:
	var out: Array[CraftStation] = []
	out.assign(_by_cell.values())
	return out


func aimed_cell() -> Vector2i:
	return view.world_to_cell(Pointer.global_position(player))


func can_reach(cell: Vector2i) -> bool:
	return player != null and map() != null and map().has_cell(cell) \
		and player.global_position.distance_to(view.cell_center(cell)) <= config.reach_px(view.tile_px())


## 이 칸에 제작대를 놓을 수 있나 — 섬 안 · 자원 없음 · 설치물 없음 · 몸이 걸치지 않음.
func is_free(cell: Vector2i) -> bool:
	return map() != null and not map().is_blocked(cell) and not _by_cell.has(cell) \
		and not _overlaps_player(cell)


func is_blocked() -> bool:
	return blocked.is_valid() and blocked.call()


## 열어 둔 제작대에서 손이 닿지 않게 멀어지면 제작 화면을 닫는다.
func _physics_process(_delta: float) -> void:
	if craft_view and craft_view.is_open() and craft_view.station \
			and not can_reach(craft_view.station.cell):
		craft_view.close()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.USE) or player == null or map() == null or is_blocked():
		return
	if try_use(aimed_cell()):
		get_viewport().set_input_as_handled()


## 좌클릭 한 번 — 열거나 설치했으면 true (도구 동작은 일어나지 않아야 한다).
func try_use(cell: Vector2i) -> bool:
	return try_open(cell) or try_place(cell)


func try_open(cell: Vector2i) -> bool:
	var station := station_at(cell)
	if station == null or craft_view == null or not can_reach(cell):
		return false
	craft_view.open_station(station, book)
	opened.emit(station)
	return true


## 손에 든 제작대 아이템을 겨눈 칸에 놓고 하나를 쓴다.
func try_place(cell: Vector2i) -> bool:
	var held = player.held_item()
	if not (held is Dictionary) or not is_station_item(str(held.get("id", ""))):
		return false
	if not can_reach(cell) or not is_free(cell):
		return false
	var station := add_station(str(held.id), cell)
	var left := int(held.get("count", 1)) - 1
	var slot := player.hotbar.selected()
	player.hotbar.set_item(slot, {"id": held.id, "count": left} if left > 0 else null)
	placed.emit(station)
	return true


## 제작대를 놓는다 (저장에서 되살릴 때도). 이미 있으면 그것을 돌려준다.
func add_station(id: String, cell: Vector2i) -> CraftStation:
	if _by_cell.has(cell):
		return _by_cell[cell]
	var station := CraftStation.create(id, cell, view.tile_px())
	add_child(station)
	_by_cell[cell] = station
	if regrowth:
		regrowth.add_structure(cell)
	return station


## 월드 저장 값 — [{"id", "cell"}].
func to_list() -> Array:
	return all().map(func(s: CraftStation) -> Dictionary: return s.to_dict())


func load_list(list: Array) -> void:
	for d in list:
		add_station(str(d["id"]), d["cell"])


## 플레이어 몸(충돌 모양)이 이 칸에 걸치나 — 걸친 채 놓으면 몸이 끼인다.
func _overlaps_player(cell: Vector2i) -> bool:
	var body := Rect2(player.global_position, Vector2.ZERO)
	for child in player.get_children():
		if child is CollisionShape2D and child.shape:
			var r: Rect2 = child.shape.get_rect()
			body = Rect2(player.global_position + child.position + r.position, r.size)
			break
	return view.cell_rect(cell).intersects(body)
