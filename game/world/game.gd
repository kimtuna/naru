class_name GameScene
extends Node2D
## 게임 씬 — 섬과 플레이어 캐릭터 · 제작대 · 밭 · 화면 아래 핫바 · 가방 · 제작 화면 (나머지는 다음 묶음들이 채운다).
## Session 이 들고 온 캐릭터와 월드를 받아 둔다. menu_exit(Esc) 는 열린 창을 닫거나, 열린 창이 없으면 설정 창을 연다.
## 설정 창의 「메인 화면으로」 · 「게임 종료」가 둘을 저장한 뒤 나간다.

const EXIT_ACTION := InputActions.MENU_EXIT

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
		swinger().setup(player(), island_view().tile_px())
		swinger().add_source(harvester().targets_near)
		regrowth().setup(island, island_view(), player())
		clock().setup(island)
		picker().setup(player(), drops(), island_view().tile_px())
		stations().setup(player(), island_view(), regrowth(), crafting_view(), RecipeBook.load_default())
		stations().load_list(world.stations)
		interactor().setup(player(), island_view())
		stations().register(interactor())
		farm().setup(player(), island_view(), regrowth(), stations(), clock(), drops())
		farm().load_list(world.tilled)
		farm().load_crops(world.crops)
		stations().farm = farm()
		farm().register(interactor())
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
	crafting_view().bind(player().hotbar.inventory)
	swinger().blocked = ui_blocks_click
	interactor().blocked = ui_blocks_click
	player().blocked = game_menu().is_open
	inventory_view().blocked = game_menu().is_open
	game_menu().set_host(Session.is_host)
	game_menu().main_menu_requested.connect(exit_to_menu)
	game_menu().quit_requested.connect(exit_game)
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


## 좌클릭 평타 — 무엇을 들었든 바라보는 방향으로 휘두른다.
func swinger() -> Swinger:
	return %Swinger


## 우클릭 상호작용 — 겨눈 오브젝트가 먼저, 없으면 손에 든 아이템의 동작.
func interactor() -> Interactor:
	return %Interactor


## 밭과 작물 — 개간 · 심기 · 물 · 수확.
func farm() -> Farm:
	return %Farm


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


## 설치한 제작대들 — 우클릭으로 놓고 연다.
func stations() -> Stations:
	return %Stations


func crafting_view() -> CraftingView:
	return %Crafting


## Esc 설정 창.
func game_menu() -> GameMenu:
	return %GameMenu


## 가방 · 제작 화면 · 설정 창이 열려 있으면 좌클릭은 휘두르지 않고 우클릭은 열거나 놓지 않는다.
func ui_blocks_click() -> bool:
	return inventory_view().is_open() or crafting_view().is_open() or game_menu().is_open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(EXIT_ACTION) and not event.is_echo():
		get_viewport().set_input_as_handled()
		on_escape()


## Esc — 설정 창이 열려 있으면 그 창에서 뒤로, 아니면 열린 창(제작 → 가방)을 하나 닫고, 열린 창이 없으면 설정 창을 연다.
func on_escape() -> void:
	if game_menu().is_open():
		game_menu().back()
	elif crafting_view().is_open():
		crafting_view().close()
	elif inventory_view().is_open():
		inventory_view().set_open(false)
	else:
		game_menu().open()


## 캐릭터와 월드를 저장하고 메인 화면으로 나간다.
func exit_to_menu() -> void:
	save_and_leave()
	Screens.go(self, Screens.MAIN_MENU)


## 캐릭터와 월드를 저장하고 게임을 끝낸다.
func exit_game() -> void:
	save_and_leave()
	Screens.quit(self)


func save_and_leave() -> void:
	store_world_state()
	Session.save_all()
	Session.clear()


## 저장할 월드 상태를 WorldData 에 옮긴다. 없앤 칸 · 시각은 섬과 같은 사전이라 이미 들어 있다.
func store_world_state() -> void:
	if world == null:
		return
	if island:
		world.world_time = island.time
	world.stations = stations().to_list()
	world.tilled = farm().to_list()
	world.crops = farm().crops_to_list()
	world.drops = dropped_items().map(func(d: DroppedItem) -> Dictionary: return d.to_dict())
