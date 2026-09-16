class_name DeathChests
extends Node2D
## 데스 상자들 — 죽으면 떨구고, 우클릭으로 열고, 시간을 흘리고, 월드에 저장한다 (spec/08_combat/damage-death.md).
## 페널티가 켜져 있을 때만 떨군다 — 월드 설정을 죽는 순간에 읽는다 (게임 중에 바꾼 값이 바로 적용된다).
## 담기는 범위는 사람 확인 전 — 임시로 가방 전부(핫바 포함).
## 시간은 월드가 돌아가는 동안의 실제 시간이다. 테스트는 time_scale 이나 advance() 로 빨리 돌린다.
## 손이 닿는 거리는 평타와 같은 값이다 (SwingConfig.reach_tiles).

signal dropped(chest: DeathChest)
signal opened(chest: DeathChest)
## 주인이 아닌 캐릭터가 열려다 거부됐다.
signal refused(chest: DeathChest, who_id: String)

## 비워 두면 damage_config.tres 를 쓴다 (타이머).
@export var config: DamageConfig
## 비워 두면 swing_config.tres 를 쓴다 (도달 거리).
@export var reach_config: SwingConfig

var player: Player
var view: IslandView
## 상자 창. 비워 두면 열지 않는다.
var chest_view: DeathChestView
## func() -> bool — 지금 데스 페널티가 켜져 있나. 비워 두면 기본값.
var penalty_on := Callable()
## 시간 배수 — 테스트가 빠르게 돌린다.
var time_scale := 1.0


func _ready() -> void:
	if config == null:
		config = DamageConfig.load_default()
	if reach_config == null:
		reach_config = SwingConfig.load_default()


func setup(who: Player, island_view: IslandView, window: DeathChestView, penalty: Callable) -> void:
	player = who
	view = island_view
	chest_view = window
	penalty_on = penalty
	player.died.connect(on_player_died)


## 이 기기 캐릭터의 id — 떨군 상자의 주인이자 여는 사람.
func local_id() -> String:
	return player.hotbar.character.id if player else ""


func is_penalty_on() -> bool:
	return penalty_on.call() if penalty_on.is_valid() else WorldSettings.DEFAULT_DEATH_PENALTY


func on_player_died(at: Vector2) -> void:
	drop_for(player.hotbar.inventory, local_id(), at)


## 죽은 캐릭터의 가방을 비워 그 자리에 상자로 떨군다. 페널티가 꺼져 있거나 가방이 비었으면 null.
func drop_for(inventory: Inventory, who_id: String, at: Vector2) -> DeathChest:
	if not is_penalty_on() or inventory == null:
		return null
	var contents := []
	for i in inventory.size():
		var it = inventory.slot(i)
		if it is Dictionary:
			contents.append(it.duplicate(true))
			inventory.set_slot(i, null)
	contents = DeathChest.clean_items(contents)
	if contents.is_empty():
		return null
	var chest := add_chest(DeathChest.create(who_id, contents, at, config.death_chest_seconds))
	dropped.emit(chest)
	return chest


func add_chest(chest: DeathChest) -> DeathChest:
	chest.name = "DeathChest_%d" % get_child_count()
	add_child(chest, true)
	return chest


## 남아 있는 상자들.
func all() -> Array[DeathChest]:
	var out: Array[DeathChest] = []
	for child in get_children():
		if child is DeathChest and not child.is_gone():
			out.append(child)
	return out


func chests_at(cell: Vector2i) -> Array[DeathChest]:
	return all().filter(func(c: DeathChest) -> bool: return view.world_to_cell(c.position) == cell)


func can_reach(chest: DeathChest) -> bool:
	return player != null and view != null \
		and player.global_position.distance_to(chest.position) <= reach_config.reach_px(view.tile_px())


## 우클릭 상호작용에 붙인다 — 상자는 오브젝트다.
func register(interactor: Interactor) -> void:
	interactor.add_object(try_open)


## 겨눈 칸의 닿는 상자를 연다 — 내 상자가 먼저. 남의 상자뿐이면 거부하지만 클릭은 먹는다.
func try_open(cell: Vector2i) -> bool:
	var here := chests_at(cell).filter(can_reach)
	if here.is_empty():
		return false
	var mine := here.filter(func(c: DeathChest) -> bool: return c.can_open(local_id()))
	open(mine[0] if not mine.is_empty() else here[0], local_id())
	return true


## 이 캐릭터로 상자를 연다. 주인이 아니면 거부하고 false.
func open(chest: DeathChest, who_id: String) -> bool:
	if chest == null or not chest.can_open(who_id):
		refused.emit(chest, who_id)
		return false
	if chest_view:
		chest_view.open_chest(chest, player.hotbar.inventory if player else null, who_id)
	opened.emit(chest)
	return true


## 모든 상자의 시간을 seconds 초 흘린다.
func advance(seconds: float) -> void:
	for chest in all():
		chest.tick(seconds)


func _process(delta: float) -> void:
	advance(delta * time_scale)
	# 열어 둔 상자에서 손이 닿지 않게 멀어지면 창을 닫는다.
	if chest_view and chest_view.is_open() and chest_view.chest and not can_reach(chest_view.chest):
		chest_view.close()


## 월드 저장 값 — [{"owner", "pos", "items", "left"}] (DeathChest.to_dict).
func to_list() -> Array:
	return all().map(func(c: DeathChest) -> Dictionary: return c.to_dict())


func load_list(list: Array) -> void:
	for d in list:
		if DeathChest.is_valid_dict(d):
			var chest := DeathChest.from_dict(d, config.death_chest_seconds)
			if not chest.items.is_empty():
				add_chest(chest)
