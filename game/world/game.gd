class_name GameScene
extends Node2D
## 게임 씬 — 섬과 플레이어 캐릭터 · 제작대 · 화면 아래 핫바 · 가방 · 제작 화면 (나머지는 다음 묶음들이 채운다).
## Session 이 들고 온 캐릭터와 월드를 받아 두고, menu_exit 액션으로 둘을 저장한 뒤 메인 화면으로 나간다.

const EXIT_ACTION := "menu_exit"

var character: CharacterData
var world: WorldData
## 월드를 만들 때 정한 시드로 만든 섬. 월드가 없으면 null.
## 보이는 곳 둘레만 먼저 만든다 — 256×256 이어도 들어가는 시간이 짧다.
var island: IslandMap
## 들어가는 데 걸린 시간 (마이크로초) — _ready 시작부터 섬을 그릴 때까지.
var load_usec := 0


func _ready() -> void:
	var started := Time.get_ticks_usec()
	character = Session.character
	world = Session.world
	if world:
		# 지형은 시드로 다시 만들고, 저장된 「없앤 칸」만 얹는다.
		island = IslandMap.new(IslandGenerator.new(world.world_seed), true, world.removed_cells, world.removed_at)
		island.time = world.world_time
		island_view().setup(island)
		harvester().setup(player(), island_view(), drops())
		regrowth().setup(island, island_view(), player())
		clock().setup(island)
		picker().setup(player(), drops(), island_view().tile_px())
		stations().setup(player(), island_view(), regrowth(), crafting_view(), RecipeBook.load_default())
		stations().load_list(world.stations)
		for d in world.drops:
			drops().add_child(DroppedItem.create({"id": d["id"], "count": d.get("count", 1)}, d["pos"]))
		island_view().follow = player()
		player().global_position = island_view().cell_center(island.spawn())
		island_view().update_around(player().global_position)
	lighting().setup(clock())
	%CharacterName.text = character_name()
	%WorldName.text = world_name()
	if character:
		player().hotbar = Hotbar.new(character)
	%Hotbar.bind(player().hotbar)
	inventory_view().bind(player().hotbar.inventory)
	harvester().blocked = ui_blocks_click
	stations().blocked = ui_blocks_click
	load_usec = Time.get_ticks_usec() - started


func character_name() -> String:
	return character.name if character else ""


func world_name() -> String:
	return world.name if world else ""


func player() -> Player:
	return %Player


func island_view() -> IslandView:
	return %Island


func harvester() -> Harvester:
	return %Harvester


func regrowth() -> Regrowth:
	return %Regrowth


## 날짜 · 낮밤 시계. 시간은 섬(island.time)에 있다.
func clock() -> WorldClock:
	return %Clock


## 밤의 어둠과 광원(램프 자리).
func lighting() -> Lighting:
	return %Lighting


func picker() -> Picker:
	return %Picker


## 바닥에 떨어진 아이템들의 부모.
func drops() -> Node2D:
	return %Drops


func dropped_items() -> Array[DroppedItem]:
	var out: Array[DroppedItem] = []
	for child in drops().get_children():
		if child is DroppedItem and not child.is_queued_for_deletion():
			out.append(child)
	return out


func hotbar_view() -> HotbarView:
	return %Hotbar


func inventory_view() -> InventoryView:
	return %Inventory


## 설치한 제작대들 — 좌클릭으로 놓고 연다.
func stations() -> Stations:
	return %Stations


func crafting_view() -> CraftingView:
	return %Crafting


## 가방이나 제작 화면이 열려 있으면 좌클릭은 휘두르거나 놓지 않는다.
func ui_blocks_click() -> bool:
	return inventory_view().is_open() or crafting_view().is_open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(EXIT_ACTION):
		get_viewport().set_input_as_handled()
		exit_to_menu()


## 캐릭터와 월드를 저장하고 메인 화면으로 나간다.
func exit_to_menu() -> void:
	store_world_state()
	Session.save_all()
	Session.clear()
	Screens.go(self, Screens.MAIN_MENU)


## 저장할 월드 상태를 WorldData 에 옮긴다. 없앤 칸 · 시각은 섬과 같은 사전이라 이미 들어 있다.
func store_world_state() -> void:
	if world == null:
		return
	if island:
		world.world_time = island.time
	world.stations = stations().to_list()
	world.drops = dropped_items().map(func(d: DroppedItem) -> Dictionary: return d.to_dict())
