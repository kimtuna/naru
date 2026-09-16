class_name Anchors
extends Node2D
## 앵커 — 소모성. 앵커를 들고 절벽 칸에 우클릭하면 그 칸에 달리고 앵커 1개가 준다 (spec/04_life/climbing.md).
## 앵커가 달린 칸에 있으면 기력이 회복된다 (Climber 가 has_anchor 로 묻는다). 달린 앵커는 월드에 저장된다.
## 입력은 Interactor 가 받아 여기로 묻는다 (register). 손이 닿는 거리는 평타와 같은 값이다 (SwingConfig.reach_tiles).
## 몸이 지나갈 수 있어 충돌은 없다. 떼는 방법은 아직 없다.

signal attached(cell: Vector2i)

const ANCHOR := "anchor"
## 색은 임시다 — 아트는 사람이 나중에 넣는다.
const COLOR := Color(0.85, 0.85, 0.9)
## 칸 크기에 대한 표시 크기.
const MARK_RATIO := 0.4

## 비워 두면 swing_config.tres 를 쓴다 (도달 거리).
@export var config: SwingConfig

var player: Player
var view: IslandView
## 달린 칸 — Vector2i → true.
var _cells := {}


func _ready() -> void:
	if config == null:
		config = SwingConfig.load_default()


func setup(who: Player, island_view: IslandView) -> void:
	player = who
	view = island_view


func register(interactor: Interactor) -> void:
	interactor.set_item_action(ANCHOR, func(_item: Dictionary, cell: Vector2i) -> bool: return place(cell))


func has_anchor(cell: Vector2i) -> bool:
	return _cells.has(cell)


## 이 위치의 칸에 앵커가 달려 있나.
func has_anchor_at(pos: Vector2) -> bool:
	return view != null and _cells.has(view.world_to_cell(pos))


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_cells.keys())
	return out


func can_reach(cell: Vector2i) -> bool:
	return player != null and view != null and view.map != null and view.map.has_cell(cell) \
		and player.global_position.distance_to(view.cell_center(cell)) <= config.reach_px(view.tile_px())


## 손에 든 앵커를 닿는 절벽 칸에 달고 하나를 쓴다. 이미 달린 칸이면 아무 일도 없다.
func place(cell: Vector2i) -> bool:
	var held = player.held_item() if player else null
	if not (held is Dictionary) or str(held.get("id", "")) != ANCHOR:
		return false
	if not can_reach(cell) or not view.map.is_cliff(cell) or _cells.has(cell):
		return false
	attach(cell)
	var left := int(held.get("count", 1)) - 1
	player.hotbar.set_item(player.hotbar.selected(), {"id": held.id, "count": left} if left > 0 else null)
	return true


## 칸에 단다 (저장에서 되살릴 때도). 거리 · 지형은 따지지 않는다.
func attach(cell: Vector2i) -> void:
	if _cells.has(cell):
		return
	_cells[cell] = true
	queue_redraw()
	attached.emit(cell)


## 월드 저장 값 — 달린 칸 목록.
func to_list() -> Array:
	return cells()


func load_list(list: Array) -> void:
	for cell in list:
		if cell is Vector2i:
			attach(cell)


func _draw() -> void:
	if view == null:
		return
	for cell: Vector2i in _cells:
		var rect := view.cell_rect(cell)
		var size := rect.size * MARK_RATIO
		draw_rect(Rect2(rect.get_center() - size / 2.0, size), COLOR)
