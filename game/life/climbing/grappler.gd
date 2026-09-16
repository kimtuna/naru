class_name Grappler
extends Node
## 갈고리총 — 들고 좌클릭하면 Pointer 쪽으로 쏘고, 걸린 곳으로 날아간다 (spec/04_life/climbing.md).
## 최대 거리(등급마다)보다 멀리 겨누면 최대 거리 지점에, 짧게 겨누면 그 지점에 걸린다.
## 날아가는 길에 막힌 칸(바다 · 자원 · 섬 밖)이 있으면 그 앞에서 멈춘다.
## 탄창이 있어 한 발마다 하나 준다. 비면 쏘지 않는다. 걸을 수 있는 땅에 서 있으면 들고 있는 갈고리총이 다시 찬다 (임시).
## 절벽 칸에 도착하면 매달린다 — 스파이크가 없어도 떨어지지 않고 기력이 준다 (Climber).
## 매달린 채로 다시 쏠 수 있다. 줄을 끊으면(cut_rope) 아래쪽 걸을 수 있는 칸까지 떨어진다.
## Swinger 의 좌클릭 동작(add_alternate)으로 걸려, 드는 동안은 휘두르지 않는다 — 채취하지 않는다.

signal fired(hook: Vector2)
## 탄창이 비어 못 쐈다.
signal dry_fired
## 걸린 곳에 닿았다 — hanging 이면 절벽에 매달렸다.
signal arrived(at: Vector2, hanging: bool)
signal rope_cut

enum State { IDLE, FLYING, HANGING }

## 비워 두면 grapple_config.tres 를 쓴다.
@export var config: GrappleConfig

var player: Player
var view: IslandView
var climber: Climber
var state := State.IDLE
## 마지막으로 갈고리가 걸린 곳.
var hook := Vector2.ZERO
## 날아가 멈출 곳 — 길이 막히지 않았으면 hook 과 같다.
var _to := Vector2.ZERO


func _ready() -> void:
	if config == null:
		config = GrappleConfig.load_default()


func setup(who: Player, island_view: IslandView, climbing: Climber) -> void:
	player = who
	view = island_view
	climber = climbing
	climber.fell.connect(_release)
	player.respawned.connect(_release)


func is_hanging() -> bool:
	return state == State.HANGING


func is_flying() -> bool:
	return state == State.FLYING


## 손에 든 것이 갈고리총이면 쏘고(탄이 있으면) 다음 발까지 기다릴 초를, 아니면 -1 을 돌려준다.
func try_fire(item: Variant) -> float:
	if not config.is_grapple(item):
		return -1.0
	fire()
	return config.stat(item, "interval")


## 손에 든 갈고리총을 Pointer 쪽으로 한 발 쏜다. 못 쐈으면 false.
func fire() -> bool:
	if player == null or view == null or is_flying() or player.falling:
		return false
	var item = player.held_item()
	if not config.is_grapple(item):
		return false
	var left := config.loaded(item)
	if left <= 0:
		dry_fired.emit()
		return false
	_set_loaded(item, left - 1)
	player.update_facing()
	var from := player.global_position
	hook = GrappleConfig.hook_point(from, Pointer.global_position(player), config.max_range_px(item, view.tile_px()))
	_to = reachable(from, hook)
	state = State.FLYING
	player.hanging = false
	player.flying = true
	player.velocity = Vector2.ZERO
	fired.emit(hook)
	return true


## from 에서 to 로 곧게 갈 때 막힌 칸에 들어가기 전 마지막 자리.
func reachable(from: Vector2, to: Vector2) -> Vector2:
	var dist := from.distance_to(to)
	var steps := ceili(dist / config.path_step_px)
	var last := from
	for i in range(1, steps + 1):
		var p := from.lerp(to, float(i) / steps)
		if view.map.is_solid(view.world_to_cell(p)):
			return last
		last = p
	return to


## 줄을 끊는다 — 절벽이면 아래쪽 걸을 수 있는 칸까지 떨어진다. 매달리거나 날아가는 중이 아니면 아무 일도 없다.
func cut_rope() -> bool:
	if state == State.IDLE:
		return false
	_release()
	rope_cut.emit()
	if climber.is_cliff_at(player.global_position):
		climber.start_fall()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.CUT_ROPE) and not event.is_echo() and player \
			and not player.is_blocked() and cut_rope():
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	match state:
		State.FLYING:
			player.global_position = player.global_position.move_toward(_to, config.fly_speed * delta)
			if player.global_position.is_equal_approx(_to):
				_arrive()
		State.IDLE:
			_reload_on_ground()


func _arrive() -> void:
	player.global_position = _to
	player.flying = false
	var on_cliff := climber.is_cliff_at(_to)
	state = State.HANGING if on_cliff else State.IDLE
	player.hanging = on_cliff
	arrived.emit(_to, on_cliff)


func _reload_on_ground() -> void:
	if player.falling or climber.is_cliff_at(player.global_position):
		return
	var item = player.held_item()
	if config.is_grapple(item) and config.loaded(item) < config.magazine(item):
		_set_loaded(item, config.magazine(item))


func _set_loaded(item: Dictionary, count: int) -> void:
	var next := item.duplicate()
	next[GrappleConfig.LOADED_KEY] = count
	player.hotbar.set_item(player.hotbar.selected(), next)


func _release() -> void:
	state = State.IDLE
	player.hanging = false
	player.flying = false
