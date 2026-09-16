class_name Farm
extends Node2D
## 밭 — 맨땅 → 개간 → 심기 → 물 → 성장 → 수확 (spec/04_life/farming.md).
## 입력은 Interactor 가 받아 여기로 묻는다 (register) — 모두 우클릭:
## - 삽: 맨땅이면 개간, 밭이면 맨땅으로 (심은 작물은 씨앗 · 수확물로 바닥에 떨어진다)
## - 씨앗: 비어 있는 밭에 심는다 (하나를 쓴다) · 물뿌리개: 심은 작물에 오늘 물을 준다
## - 다 자란 작물: 무엇을 들었든 수확한다 (상호작용 오브젝트) — 작물이 바닥에 떨어지고 밭은 남는다
## 날이 넘어갈 때(WorldClock.day_changed) 물을 받은 작물만 하루 자라고, 물은 마른다.
## 맨땅 = 섬 안 · 자원 없음 · 제작대 없음. 손이 닿는 거리는 평타와 같은 값이다 (SwingConfig.reach_tiles).
## 밭은 설치물이다 — 둘레에 자원이 다시 자라지 않게 Regrowth 에 알린다. 몸이 지나갈 수 있어 충돌은 없다.

signal tilled(cell: Vector2i)
signal untilled(cell: Vector2i)
signal planted(cell: Vector2i)
signal watered(cell: Vector2i)
signal harvested(cell: Vector2i, drop: DroppedItem)

const SHOVEL := "shovel"
## 색은 임시다 — 아트는 사람이 나중에 넣는다.
const SOIL_COLOR := Color(0.45, 0.3, 0.18)
const WET_SOIL_COLOR := Color(0.3, 0.2, 0.12)
const CROP_COLOR := Color(0.4, 0.75, 0.3)
const RIPE_COLOR := Color(0.95, 0.8, 0.3)

## 비워 두면 swing_config.tres 를 쓴다 (도달 거리).
@export var config: SwingConfig
## 비워 두면 farm_config.tres 를 쓴다.
@export var farm_config: FarmConfig

var player: Player
var view: IslandView
## 비워 두면 알리지 않는다.
var regrowth: Regrowth
## 제작대가 놓인 칸은 개간하지 않는다. 비워 두면 따지지 않는다.
var stations: Stations
## 수확물 · 되돌린 씨앗을 넣을 노드. 비워 두면 떨어뜨리지 않는다.
var drops: Node2D
## 간 밭 — Vector2i → true.
var _tilled := {}
## 심은 작물 — Vector2i → Crop.
var _crops := {}


func _ready() -> void:
	if config == null:
		config = SwingConfig.load_default()
	if farm_config == null:
		farm_config = FarmConfig.load_default()


func setup(who: Player, island_view: IslandView, regrow: Regrowth, placed: Stations,
		clock: WorldClock = null, drops_parent: Node2D = null) -> void:
	player = who
	view = island_view
	regrowth = regrow
	stations = placed
	drops = drops_parent
	if clock:
		clock.day_changed.connect(func(_day: int) -> void: pass_day())


func register(interactor: Interactor) -> void:
	interactor.add_object(harvest)
	interactor.set_item_action(SHOVEL, func(_item: Dictionary, cell: Vector2i) -> bool: return dig(cell))
	interactor.set_item_action(farm_config.seed_id, func(_item: Dictionary, cell: Vector2i) -> bool: return plant(cell))
	interactor.set_item_action(farm_config.watering_can_id,
		func(_item: Dictionary, cell: Vector2i) -> bool: return water(cell))


func map() -> IslandMap:
	return view.map if view else null


func is_tilled(cell: Vector2i) -> bool:
	return _tilled.has(cell)


func tilled_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_tilled.keys())
	return out


func crop_at(cell: Vector2i) -> Crop:
	return _crops.get(cell)


func is_ripe(cell: Vector2i) -> bool:
	return _crops.has(cell) and _crops[cell].is_ripe(farm_config.grow_days)


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


## 맨땅으로 돌린다. 심은 작물은 씨앗(다 자랐으면 수확물)으로 바닥에 떨어진다.
func untill(cell: Vector2i) -> void:
	if not _tilled.erase(cell):
		return
	var crop: Crop = _crops.get(cell)
	if crop:
		_crops.erase(cell)
		var ripe := crop.is_ripe(farm_config.grow_days)
		_drop(cell, crop.id if ripe else farm_config.seed_id, farm_config.harvest_count if ripe else 1)
	if regrowth:
		regrowth.remove_structure(cell)
	queue_redraw()
	untilled.emit(cell)


## 손에 든 씨앗을 비어 있는 밭에 심고 하나를 쓴다.
func plant(cell: Vector2i) -> bool:
	var held = player.held_item() if player else null
	if not (held is Dictionary) or str(held.get("id", "")) != farm_config.seed_id:
		return false
	if not can_reach(cell) or not _tilled.has(cell) or _crops.has(cell):
		return false
	add_crop(cell, Crop.create(farm_config.crop_id))
	var left := int(held.get("count", 1)) - 1
	player.hotbar.set_item(player.hotbar.selected(), {"id": held.id, "count": left} if left > 0 else null)
	planted.emit(cell)
	return true


## 작물을 밭에 둔다 (저장에서 되살릴 때도). 밭이 아니면 두지 않는다.
func add_crop(cell: Vector2i, crop: Crop) -> void:
	if not _tilled.has(cell):
		return
	_crops[cell] = crop
	queue_redraw()


## 심은 작물에 오늘 물을 준다. 이미 줬거나 다 자랐으면 아무 일도 없다.
func water(cell: Vector2i) -> bool:
	var crop: Crop = _crops.get(cell)
	if crop == null or crop.watered or crop.is_ripe(farm_config.grow_days) or not can_reach(cell):
		return false
	crop.watered = true
	queue_redraw()
	watered.emit(cell)
	return true


## 날이 넘어갔다 — 물을 받은 작물만 하루 자란다. 자란 칸들.
func pass_day() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell: Vector2i in _crops:
		if _crops[cell].pass_day(farm_config.grow_days):
			out.append(cell)
	queue_redraw()
	return out


## 다 자란 작물을 거둔다 — 작물이 바닥에 떨어지고 밭은 남는다. 무엇을 들었든 된다.
func harvest(cell: Vector2i) -> bool:
	if not is_ripe(cell) or not can_reach(cell):
		return false
	var crop: Crop = _crops[cell]
	_crops.erase(cell)
	var drop := _drop(cell, crop.id, farm_config.harvest_count)
	queue_redraw()
	harvested.emit(cell, drop)
	return true


func _drop(cell: Vector2i, id: String, count: int) -> DroppedItem:
	if drops == null:
		return null
	var drop := DroppedItem.create({"id": id, "count": count}, view.cell_center(cell))
	drops.add_child(drop)
	return drop


## 월드 저장 값 — 간 칸 목록.
func to_list() -> Array:
	return tilled_cells()


func load_list(list: Array) -> void:
	for cell in list:
		if cell is Vector2i:
			till(cell)


## 월드 저장 값 — [{"cell", "id", "days", "watered"}] (Crop.to_dict).
func crops_to_list() -> Array:
	return _crops.keys().map(func(cell: Vector2i) -> Dictionary: return _crops[cell].to_dict(cell))


func load_crops(list: Array) -> void:
	for d in list:
		if Crop.is_valid_dict(d):
			add_crop(d.cell, Crop.from_dict(d))


func _draw() -> void:
	if view == null:
		return
	for cell: Vector2i in _tilled:
		var crop: Crop = _crops.get(cell)
		var rect := view.cell_rect(cell)
		draw_rect(rect, WET_SOIL_COLOR if crop and crop.watered else SOIL_COLOR)
		if crop == null:
			continue
		# 자랄수록 커진다.
		var grown := float(mini(crop.days, farm_config.grow_days) + 1) / float(farm_config.grow_days + 1)
		var size := rect.size * 0.8 * grown
		var color := RIPE_COLOR if crop.is_ripe(farm_config.grow_days) else CROP_COLOR
		draw_rect(Rect2(rect.get_center() - size / 2.0, size), color)
