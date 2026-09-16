class_name Harvester
extends Node
## 좌클릭 채취 — 겨눈 칸(Pointer)과 손에 든 것(핫바)이 동작을 정한다.
## 맞는 조합이고 손이 닿으면 휘두를 때마다 힘을 쌓고, 다 쌓이면 칸을 비우고 아이템을 바닥에 떨어뜨린다.
## 좌클릭을 쥐고 있으면 swing_interval 마다 이어서 휘두른다. 겨눈 칸이 바뀌면 쌓인 힘은 사라진다.
## blocked 가 참인 동안(가방이 열려 있는 동안)은 휘두르지 않는다. 쥔 채로 풀리면 이어서 휘두른다.

signal harvested(cell: Vector2i, deposit: IslandConfig.Deposit, drop: DroppedItem)

const NO_CELL := Vector2i(-1, -1)

## 비워 두면 harvest_config.tres 를 쓴다.
@export var config: HarvestConfig

var player: Player
var view: IslandView
## 떨어진 아이템을 넣을 노드.
var drops: Node2D
## 참을 돌려주면 좌클릭으로 휘두르지 않는다. 비워 두면 막지 않는다.
var blocked := Callable()
var _holding := false
var _cooldown := 0.0
var _target := NO_CELL
var _progress := 0


func _ready() -> void:
	if config == null:
		config = HarvestConfig.load_default()


func setup(who: Player, island_view: IslandView, drops_parent: Node2D) -> void:
	player = who
	view = island_view
	drops = drops_parent


func map() -> IslandMap:
	return view.map if view else null


## 겨눈 칸에 쌓인 힘 (0 이면 아직 안 쳤다).
func progress_at(cell: Vector2i) -> int:
	return _progress if cell == _target else 0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.USE):
		_holding = true
		_cooldown = 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not Input.is_action_pressed(InputActions.USE):
		_holding = false
	if not _holding or _cooldown > 0.0 or player == null or map() == null or is_blocked():
		return
	if swing(aimed_cell()):
		_cooldown = config.swing_interval


func is_blocked() -> bool:
	return blocked.is_valid() and blocked.call()


## 커서가 가리키는 칸.
func aimed_cell() -> Vector2i:
	return view.world_to_cell(Pointer.global_position(player))


func can_reach(cell: Vector2i) -> bool:
	return map().has_cell(cell) \
		and player.global_position.distance_to(view.cell_center(cell)) <= config.reach_px(view.tile_px())


## 지금 손에 든 것으로 이 칸을 칠 수 있나 (거리 포함).
func can_swing_at(cell: Vector2i) -> bool:
	if player == null or map() == null or not can_reach(cell):
		return false
	var tool := HarvestConfig.tool_of(player.held_item())
	return HarvestConfig.can_harvest(tool, map().deposit_at(cell))


## 한 번 휘두른다. 아무 일도 없으면 false.
func swing(cell: Vector2i) -> bool:
	if not can_swing_at(cell):
		return false
	if cell != _target:
		_target = cell
		_progress = 0
	_progress += config.power_of(HarvestConfig.tool_of(player.held_item()))
	if _progress >= config.deposit_hp:
		_target = NO_CELL
		_progress = 0
		_harvest(cell)
	return true


func _harvest(cell: Vector2i) -> void:
	var deposit := map().deposit_at(cell)
	map().remove_deposit(cell)
	var item := {"id": HarvestConfig.DROPS[deposit], "count": config.drop_count}
	var drop := DroppedItem.create(item, view.cell_center(cell))
	drops.add_child(drop)
	harvested.emit(cell, deposit, drop)
