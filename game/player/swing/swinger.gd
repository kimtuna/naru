class_name Swinger
extends Node
## 좌클릭 평타 — 무엇을 들었든(맨손 포함) 바라보는 방향으로 휘두른다 (spec/02_player/movement-controls.md).
## 좌클릭을 쥐고 있으면 swing_interval 마다 이어서 휘두른다.
## 맞는 대상은 등록된 출처(add_source)가 내놓은 SwingTarget 중에서 SwingAim 이 고른다 —
## 자원(Harvester)과 몹(G-009)이 같은 경로로 들어온다.
## 손에 든 것이 휘두르지 않고 다른 동작을 하면(총 → 쏘기) alternate 가 맡는다.
## blocked 가 참인 동안(가방 · 제작 화면이 열려 있는 동안)은 휘두르지 않는다. 쥔 채로 풀리면 이어서 휘두른다.

signal swung(facing: Vector2, target: SwingTarget)

## 비워 두면 swing_config.tres 를 쓴다.
@export var config: SwingConfig

var player: Player
var tile_px := 16
## 참을 돌려주면 좌클릭으로 휘두르지 않는다. 비워 두면 막지 않는다.
var blocked := Callable()
## 좌클릭을 휘두르기 대신 맡는 동작: func(item: Variant) -> float.
## 맡았으면 다음 동작까지 기다릴 초, 맡지 않으면 음수. 비워 두면 늘 휘두른다.
var alternate := Callable()
## 휘두른 횟수 (맞은 것이 없어도 센다).
var swing_count := 0
var _sources: Array[Callable] = []
var _holding := false
var _cooldown := 0.0
var _show_left := 0.0


func _ready() -> void:
	if config == null:
		config = SwingConfig.load_default()


func setup(who: Player, tile_size: int) -> void:
	player = who
	tile_px = tile_size


## 맞을 수 있는 대상을 내놓는 곳: func(origin: Vector2, reach: float) -> Array (SwingTarget 들).
func add_source(source: Callable) -> void:
	_sources.append(source)


func reach_px() -> float:
	return config.reach_px(tile_px)


## 좌클릭을 받아 쥐고 있는 중인가 (다른 동작이 입력을 먹었으면 false).
func is_holding() -> bool:
	return _holding


func is_blocked() -> bool:
	return blocked.is_valid() and blocked.call()


## 휘두른 표시가 보이는 중인가.
func is_showing() -> bool:
	return _show_left > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.USE):
		_holding = true
		_cooldown = 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_show_left = maxf(_show_left - delta, 0.0)
	if player:
		player.show_swing(is_showing())
	if not Input.is_action_pressed(InputActions.USE):
		_holding = false
	if not _holding or _cooldown > 0.0 or player == null or is_blocked():
		return
	_cooldown = use()


## 좌클릭 한 번 — 맡는 동작이 있으면 그것을, 없으면 휘두른다. 다음 동작까지 기다릴 초.
func use() -> float:
	if alternate.is_valid():
		var wait: float = alternate.call(player.held_item())
		if wait >= 0.0:
			return wait
	swing()
	return config.swing_interval


## 지금 휘두르면 맞을 대상 (없으면 null).
func target() -> SwingTarget:
	if player == null:
		return null
	var origin := player.global_position
	var candidates := []
	for source in _sources:
		if source.is_valid():
			candidates.append_array(source.call(origin, reach_px()))
	return SwingAim.pick(origin, player.facing, reach_px(), config.half_arc(), candidates)


## 한 번 휘두른다 — 늘 휘두르고, 맞은 대상을 돌려준다 (없으면 null).
func swing() -> SwingTarget:
	player.update_facing()
	var hit := target()
	if hit:
		hit.hit(player.held_item())
	swing_count += 1
	_show_left = config.show_time
	player.show_swing(true)
	swung.emit(player.facing, hit)
	return hit
