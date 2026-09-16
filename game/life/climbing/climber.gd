class_name Climber
extends Node
## 절벽 등반 — 캐릭터가 절벽 칸에 있는 동안 기력을 쓰고, 여유까지 다 쓰면 떨어뜨린다 (spec/04_life/climbing.md).
## 떨어지면 아래쪽(+y)으로 걸을 수 있는 칸이 나올 때까지 내려가고, 닿으면 낙하 피해를 받는다.
## 앵커가 달린 칸에 있으면 기력이 차오른다 (anchors).
## 스파이크 없이 절벽 칸에 있게 되면(절벽에서 스파이크를 뺐을 때) 바로 떨어진다. 갈고리총에 매달려 있으면 떨어지지 않는다.
## 매달린 동안은 움직이지 않아도 기력이 준다. 날아가는 동안은 기력이 그대로다.

## 떨어지기 시작했다 (이 신호 동안 stamina.overdraw 는 아직 떨어진 순간의 값이다).
signal fell
## 떨어져 닿았다 — 받은 낙하 피해.
signal landed(damage: float)

## 이만큼(픽셀) 넘게 움직여야 「움직이는 중」이다.
const MOVE_EPS := 0.01
const NO_CELL := Vector2i(-1, -1)

var config := ClimbingConfig.load_default()
var stamina := Stamina.new(config)
var player: Player
var view: IslandView
## 앵커가 달린 칸을 묻는다. 비워 두면 앵커가 없다.
var anchors: Anchors
var _falling := false
var _fall_to := Vector2.ZERO


func setup(target: Player, island_view: IslandView, placed: Anchors = null) -> void:
	player = target
	view = island_view
	anchors = placed
	player.on_cliff = is_cliff_at
	player.climb_speed = config.climb_speed
	player.respawned.connect(_on_respawned)


## 이 위치의 칸이 절벽인가.
func is_cliff_at(pos: Vector2) -> bool:
	if view == null or view.map == null:
		return false
	var cell := view.world_to_cell(pos)
	return view.map.has_cell(cell) and view.map.is_cliff(cell)


func is_falling() -> bool:
	return _falling


## 절벽에 붙어 있다 (떨어지는 중이 아니다).
func is_climbing() -> bool:
	return player != null and not _falling and is_cliff_at(player.global_position)


## 기력 표시를 보일까 — 절벽에 있거나 아직 다 차지 않았다.
func shows_stamina() -> bool:
	return is_climbing() or not stamina.is_full()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	if _falling:
		_fall_step(delta)
		return
	if player.flying:
		return
	var on := is_cliff_at(player.global_position)
	if on and not player.can_climb() and not player.hanging:
		start_fall()
		return
	var moving := player.last_motion.length() > MOVE_EPS
	var anchored := anchors != null and anchors.has_anchor_at(player.global_position)
	if stamina.tick(delta, on, moving, anchored, on and player.hanging):
		start_fall()


## 떨어지기 시작한다 — 아래쪽으로 걸을 수 있는 칸을 찾는다. 없으면 스폰 지점에 떨어진다.
func start_fall() -> void:
	if player == null or _falling:
		return
	var land := landing_cell(view.world_to_cell(player.global_position))
	player.hanging = false
	fell.emit()
	stamina.clear_overdraw()
	if land == NO_CELL:
		player.global_position = player.spawn_point
		_land()
		return
	_fall_to = view.cell_center(land)
	_falling = true
	player.falling = true
	player.velocity = Vector2.ZERO
	player.global_position.x = _fall_to.x


## from 아래쪽(+y)으로 처음 나오는 걸을 수 있는 칸. 없으면 NO_CELL.
func landing_cell(from: Vector2i) -> Vector2i:
	var map := view.map
	for y in range(from.y + 1, map.size):
		var c := Vector2i(from.x, y)
		if not map.is_blocked(c):
			return c
	return NO_CELL


func _fall_step(delta: float) -> void:
	var pos := player.global_position
	pos.y = move_toward(pos.y, _fall_to.y, config.fall_speed * delta)
	player.global_position = pos
	if is_equal_approx(pos.y, _fall_to.y):
		_land()


func _land() -> void:
	_falling = false
	player.falling = false
	player.velocity = Vector2.ZERO
	landed.emit(config.fall_damage)
	player.take_damage(config.fall_damage)


func _on_respawned() -> void:
	_falling = false
	player.falling = false
	stamina.refill()
