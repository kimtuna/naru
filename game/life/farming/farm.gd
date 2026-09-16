class_name Farm
extends Node2D
## 밭 — 삽을 들고 우클릭해 개간하고, 간 밭에 다시 우클릭하면 맨땅으로 돌린다 (spec/04_life/farming.md).
## 입력은 Interactor 가 받아 여기로 묻는다 (register) — 삽의 우클릭 동작.
## 맨땅 = 섬 안 · 자원 없음 · 제작대 없음. 손이 닿는 거리는 평타와 같은 값이다 (SwingConfig.reach_tiles).
## 밭은 설치물이다 — 둘레에 자원이 다시 자라지 않게 Regrowth 에 알린다. 몸이 지나갈 수 있어 충돌은 없다.

signal tilled(cell: Vector2i)
signal untilled(cell: Vector2i)

const SHOVEL := "shovel"
## 색은 임시다 — 아트는 사람이 나중에 넣는다.
const SOIL_COLOR := Color(0.45, 0.3, 0.18)

## 비워 두면 swing_config.tres 를 쓴다 (도달 거리).
@export var config: SwingConfig

var player: Player
var view: IslandView
## 비워 두면 알리지 않는다.
var regrowth: Regrowth
## 제작대가 놓인 칸은 개간하지 않는다. 비워 두면 따지지 않는다.
var stations: Stations
## 간 밭 — Vector2i → true.
var _tilled := {}


func _ready() -> void:
	if config == null:
		config = SwingConfig.load_default()


func setup(who: Player, island_view: IslandView, regrow: Regrowth, placed: Stations) -> void:
	player = who
	view = island_view
	regrowth = regrow
	stations = placed


func register(interactor: Interactor) -> void:
	interactor.set_item_action(SHOVEL, func(_item: Dictionary, cell: Vector2i) -> bool: return dig(cell))


func map() -> IslandMap:
	return view.map if view else null


func is_tilled(cell: Vector2i) -> bool:
	return _tilled.has(cell)


func tilled_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_tilled.keys())
	return out


func can_reach(cell: Vector2i) -> bool:
	return player != null and map() != null and map().has_cell(cell) \
		and player.global_position.distance_to(view.cell_center(cell)) <= config.reach_px(view.tile_px())


## 개간할 수 있는 맨땅인가 — 섬 안 · 자원 없음 · 제작대 없음 · 아직 밭이 아님.
func is_bare(cell: Vector2i) -> bool:
	return map() != null and not map().is_blocked(cell) and not _tilled.has(cell) \
		and not (stations and stations.station_at(cell))


## 삽으로 이 칸을 한 번 — 맨땅이면 밭으로, 밭이면 맨땅으로. 무언가 했으면 true.
func dig(cell: Vector2i) -> bool:
	if not can_reach(cell):
		return false
	if _tilled.has(cell):
		untill(cell)
		return true
	if not is_bare(cell):
		return false
	till(cell)
	return true


## 밭으로 만든다 (저장에서 되살릴 때도). 거리 · 자원은 따지지 않는다.
func till(cell: Vector2i) -> void:
	if _tilled.has(cell):
		return
	_tilled[cell] = true
	if regrowth:
		regrowth.add_structure(cell)
	queue_redraw()
	tilled.emit(cell)


func untill(cell: Vector2i) -> void:
	if not _tilled.erase(cell):
		return
	if regrowth:
		regrowth.remove_structure(cell)
	queue_redraw()
	untilled.emit(cell)


## 월드 저장 값 — 간 칸 목록.
func to_list() -> Array:
	return tilled_cells()


func load_list(list: Array) -> void:
	for cell in list:
		if cell is Vector2i:
			till(cell)


func _draw() -> void:
	if view == null:
		return
	for cell: Vector2i in _tilled:
		draw_rect(view.cell_rect(cell), SOIL_COLOR)
