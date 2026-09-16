class_name Regrowth
extends Node
## 자원 재생 — 주기가 지난 칸의 없앤 표시를 지운다 (칸은 시드의 원래 값으로 돌아간다).
## spec/03_world/resources-regrowth.md: 설치물 둘레 · 플레이어가 선 칸에는 자라지 않는다 — 비켜날 때까지 기다린다.
## 「부족한 만큼 채우기」는 하지 않는다 — 원래 값으로만 돌아가니 비율이 저절로 지켜진다.

signal regrown(cell: Vector2i)

## 비워 두면 regrowth_config.tres 를 쓴다.
@export var config: RegrowthConfig

var map: IslandMap
var view: IslandView
## 몸이 선 칸에는 자라지 않는다. 비워 두면 따지지 않는다.
var player: Node2D
## 설치물이 놓인 칸 — Vector2i → true. 짓기 · 밭 · 길이 add_structure 로 알린다.
var structures: Dictionary = {}
var _since_check := 0.0


func _ready() -> void:
	if config == null:
		config = RegrowthConfig.load_default()


func setup(island: IslandMap, island_view: IslandView, who: Node2D) -> void:
	map = island
	view = island_view
	player = who


func add_structure(cell: Vector2i) -> void:
	structures[cell] = true


func remove_structure(cell: Vector2i) -> void:
	structures.erase(cell)


## 게임에서 시간은 WorldClock 이 흘린다 — 여기서는 check_interval 마다 훑기만 한다.
func _process(delta: float) -> void:
	tick(delta)


## 월드 시간을 delta 초 흘리고 훑는다 (시계 없이 재생만 시험할 때).
func advance(delta: float) -> void:
	if map == null:
		return
	map.time += delta
	tick(delta)


## check_interval 이 쌓이면 한 번 훑는다.
func tick(delta: float) -> void:
	if map == null:
		return
	_since_check += delta
	if _since_check >= config.check_interval:
		_since_check = 0.0
		check()


## 주기가 지났고 막히지 않은 칸을 모두 재생한다. 재생한 칸들.
func check() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell: Vector2i in map.removed.keys():
		if is_due(cell) and not is_protected(cell):
			map.regrow(cell)
			out.append(cell)
			regrown.emit(cell)
	return out


## 없앤 뒤 이 칸 자원의 주기가 지났나.
func is_due(cell: Vector2i) -> bool:
	return map.time - map.removed_time(cell) >= config.period_of(map.original_deposit(cell))


## 여기에는 지금 자라면 안 되나 — 설치물 둘레, 플레이어 몸이 걸친 칸.
func is_protected(cell: Vector2i) -> bool:
	return near_structure(cell) or cell in player_cells()


func near_structure(cell: Vector2i) -> bool:
	var r := config.structure_radius
	for s: Vector2i in structures:
		if absi(s.x - cell.x) <= r and absi(s.y - cell.y) <= r:
			return true
	return false


## 플레이어 몸(충돌 모양)이 걸친 칸들.
func player_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if player == null or view == null:
		return out
	var body := _body_rect()
	var lo := view.world_to_cell(body.position)
	# 끝 모서리에 딱 닿은 칸은 걸친 것이 아니다.
	var hi := view.world_to_cell(body.end - Vector2(0.001, 0.001))
	for y in range(lo.y, hi.y + 1):
		for x in range(lo.x, hi.x + 1):
			out.append(Vector2i(x, y))
	return out


func _body_rect() -> Rect2:
	var pos := player.global_position
	for child in player.get_children():
		if child is CollisionShape2D and child.shape:
			var r: Rect2 = child.shape.get_rect()
			return Rect2(pos + child.position + r.position, r.size)
	return Rect2(pos, Vector2.ZERO)
