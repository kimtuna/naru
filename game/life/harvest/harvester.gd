class_name Harvester
extends Node
## 채취 — 좌클릭 평타(Swinger)에 맞은 자원 칸에 힘을 쌓고, 다 쌓이면 칸을 비우고 아이템을 바닥에 떨어뜨린다.
## 손 둘레의 자원 칸을 SwingTarget 으로 내놓는다 (targets_near) — 무엇이 맞을지는 Swinger 가 고른다.
## 맞는 도구는 빠르고, 맞지 않는 도구 · 맨손은 느리다. 캘 수 없는 조합(맨손 → 광물)은 맞아도 아무 일도 없다.
## 다른 칸을 치면 앞 칸에 쌓인 힘은 사라진다.

signal harvested(cell: Vector2i, deposit: IslandConfig.Deposit, drop: DroppedItem)

const NO_CELL := Vector2i(-1, -1)

## 비워 두면 harvest_config.tres 를 쓴다.
@export var config: HarvestConfig
## 비워 두면 swing_config.tres 를 쓴다 (손이 닿는 거리).
@export var swing_config: SwingConfig

var player: Player
var view: IslandView
## 떨어진 아이템을 넣을 노드.
var drops: Node2D
var _target := NO_CELL
var _progress := 0


func _ready() -> void:
	if config == null:
		config = HarvestConfig.load_default()
	if swing_config == null:
		swing_config = SwingConfig.load_default()


func setup(who: Player, island_view: IslandView, drops_parent: Node2D) -> void:
	player = who
	view = island_view
	drops = drops_parent


func map() -> IslandMap:
	return view.map if view else null


## 이 칸에 쌓인 힘 (0 이면 아직 안 쳤다).
func progress_at(cell: Vector2i) -> int:
	return _progress if cell == _target else 0


func can_reach(cell: Vector2i) -> bool:
	return map().has_cell(cell) and player.global_position.distance_to(view.cell_center(cell)) \
		<= swing_config.reach_px(view.tile_px())


## 이 아이템으로 이 칸을 쳐서 채취가 진행되나 (거리 포함).
func can_hit(cell: Vector2i, item: Variant) -> bool:
	if player == null or map() == null or not can_reach(cell):
		return false
	return HarvestConfig.can_harvest(HarvestConfig.tool_of(item), map().deposit_at(cell))


## 지금 손에 든 것으로 이 칸을 친다. 아무 일도 없으면 false.
func swing(cell: Vector2i) -> bool:
	return player != null and hit(cell, player.held_item())


## 이 아이템으로 이 칸을 한 번 친다. 아무 일도 없으면 false.
func hit(cell: Vector2i, item: Variant) -> bool:
	if not can_hit(cell, item):
		return false
	if cell != _target:
		_target = cell
		_progress = 0
	var deposit := map().deposit_at(cell)
	_progress += config.power_of(HarvestConfig.tool_of(item), deposit)
	if _progress >= config.deposit_hp:
		_target = NO_CELL
		_progress = 0
		_harvest(cell)
	return true


## origin 둘레 reach 안의 자원 칸들 — 평타가 맞을 수 있는 대상.
## 캘 수 없는 자원(맨손 → 광물)도 넣는다: 맞기는 하고(뒤를 가린다) 아무 일도 없다.
func targets_near(origin: Vector2, reach: float) -> Array:
	var out := []
	if map() == null:
		return out
	var tile := view.tile_px()
	var lo := view.world_to_cell(origin - Vector2(reach, reach))
	var hi := view.world_to_cell(origin + Vector2(reach, reach))
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			var cell := Vector2i(x, y)
			if not map().has_cell(cell) or map().deposit_at(cell) == IslandConfig.Deposit.NONE:
				continue
			var center := view.cell_center(cell)
			if origin.distance_to(center) > reach:
				continue
			out.append(SwingTarget.create(center, tile / 2.0, func(item: Variant) -> bool: return hit(cell, item), cell))
	return out


func _harvest(cell: Vector2i) -> void:
	var deposit := map().deposit_at(cell)
	map().remove_deposit(cell)
	var item := {"id": HarvestConfig.DROPS[deposit], "count": config.drop_count}
	var drop := DroppedItem.create(item, view.cell_center(cell))
	drops.add_child(drop)
	harvested.emit(cell, deposit, drop)
