extends "res://tests/settings/display/fit_test_base.gd"
## G-010 2단계 — 모든 화면이 기준 화면 640×360 안에 잘리지 않고 들어간다.
## 글자 크기는 test_font_size.gd 가 본다.
## 한국어 · 영어 둘 다, 목록 · 오류 줄 · 확인 창이 가장 많이 보이는 상태로 본다.

const LOCALES := ["ko", "en"]
## 소수점 배치 오차.
const EPS := 0.01


func _set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	await wait_process_frames(3)


func _is_in_scroll(c: Node, top: Node) -> bool:
	var p := c.get_parent()
	while p and p != top:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


## 보이는 Control 전부 — 화면 안에 들어가고, 최소 크기보다 작게 눌려 잘리지 않는다.
func _assert_fits(top: Node, what: String) -> void:
	assert_eq(get_viewport().get_visible_rect().size, SCREEN.size, "test screen is not the base screen")
	var nodes: Array[Node] = [top]
	nodes.append_array(top.find_children("*", "Control", true, false))
	var checked := 0
	for n in nodes:
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		checked += 1
		var r := c.get_global_rect()
		var where := "%s [%s] %s rect %s" % [what, TranslationServer.get_locale(), top.get_path_to(c), r]
		if not _is_in_scroll(c, top):
			assert_true(SCREEN.grow(EPS).encloses(r), where + " is outside 640x360")
		var need := c.get_combined_minimum_size()
		assert_true(c.size.x + EPS >= need.x and c.size.y + EPS >= need.y,
			"%s is squeezed below its minimum %s" % [where, need])
		if c is Label and not (c as Label).clip_text and (c as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
			assert_true(c.size.x + EPS >= (c as Label).get_minimum_size().x, where + " text is cut")
	assert_gte(checked, 3, what + ": nothing visible to check")


## 나란히 놓인 덩어리(직계 자식)끼리 겹치지 않는다.
func _assert_blocks_apart(parent: Node, what: String) -> void:
	var blocks: Array[Control] = []
	for child in parent.get_children():
		if child is Control and child.is_visible_in_tree():
			blocks.append(child)
	for i in blocks.size():
		for j in range(i + 1, blocks.size()):
			var a := blocks[i].get_global_rect()
			var b := blocks[j].get_global_rect()
			assert_false(a.grow(-EPS).intersects(b.grow(-EPS)), "%s [%s] %s %s overlaps %s %s" % [
				what, TranslationServer.get_locale(), blocks[i].name, a, blocks[j].name, b])


func _check_screen(screen: Node, what: String) -> void:
	_assert_fits(screen, what)
	_assert_blocks_apart(screen, what)


# --- 메뉴 화면 ---

func test_main_menu_and_settings_fit() -> void:
	for path in [Screens.MAIN_MENU, Screens.SETTINGS]:
		var screen := _open(path)
		for locale in LOCALES:
			await _set_locale(locale)
			_check_screen(screen, path)


func test_character_select_fits_with_full_slots_and_confirm() -> void:
	for slot in SaveConfig.CHARACTER_SLOTS:
		_character(slot, LONG_NAME)
	var screen := _open(Screens.CHARACTER_SELECT)
	screen.delete_button(0).pressed.emit()
	assert_true(screen.get_node("%Confirm").visible, "setup: confirm is open")
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(screen, "character select")


func test_character_select_fits_with_empty_slots() -> void:
	var screen := _open(Screens.CHARACTER_SELECT)
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(screen, "character select (empty)")


func test_character_create_fits_with_errors_shown() -> void:
	var screen := _open(Screens.CHARACTER_CREATE)
	screen.get_node("%NameEdit").text = LONG_NAME
	screen.get_node("%NameError").show()
	screen.get_node("%SlotsFull").show()
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(screen, "character create")
		_assert_blocks_apart(screen.get_node("Form"), "character create form")


func test_world_select_fits_with_many_worlds_errors_and_confirm() -> void:
	_character(0, "tester")
	Session.select_character(0)
	for i in 12:
		Session.store.create_world(WorldData.create(LONG_NAME, i))
	var screen := _open(Screens.WORLD_SELECT)
	assert_eq(screen.listed_ids().size(), 12)
	screen.get_node("%NameError").show()
	screen.get_node("%CreateFailed").show()
	screen.delete_button(screen.listed_ids()[0]).pressed.emit()
	assert_true(screen.get_node("%Confirm").visible, "setup: confirm is open")
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(screen, "world select")
	# 넘치는 목록은 스크롤로 본다 — 목록의 마지막 월드까지 닿을 수 있다.
	var last: Button = screen.world_button(screen.listed_ids()[11])
	var scroll := last.get_parent().get_parent().get_parent() as ScrollContainer
	assert_not_null(scroll, "world list is not scrollable")
	if scroll:
		assert_true(SCREEN.encloses(scroll.get_global_rect()))
		scroll.ensure_control_visible(last)
		await wait_process_frames(2)
		assert_true(scroll.get_global_rect().grow(EPS).encloses(last.get_global_rect()),
			"last world cannot be scrolled into view")


func test_world_select_fits_when_empty() -> void:
	var screen := _open(Screens.WORLD_SELECT)
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(screen, "world select (empty)")


# --- 게임 화면 ---

func _hud(game: GameScene) -> CanvasLayer:
	return game.get_node("Hud") as CanvasLayer


func test_game_hud_fits_with_full_hotbar() -> void:
	var game := _enter()
	_fill_bag(game)
	game.player().hotbar.select(InventoryConfig.HOTBAR_SIZE)
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(_hud(game), "game hud")
	assert_eq(game.hotbar_view().slot_count(), InventoryConfig.HOTBAR_SIZE)


func test_inventory_fits_when_open() -> void:
	var game := _enter()
	_fill_bag(game)
	game.inventory_view().set_open(true)
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(_hud(game), "inventory")
	assert_eq(game.inventory_view().slot_count(), InventoryConfig.BAG_SIZE)


func test_crafting_fits_with_all_recipes_progress_and_full_buffer() -> void:
	var game := _enter()
	var book := RecipeBook.load_default()
	var station := game.stations().add_station("workbench", game.island.spawn() + Vector2i(3, 0))
	var recipes := book.recipes_at("workbench")
	assert_gt(recipes.size(), 0)
	# 버퍼는 아이템마다 한 줄 — 이 제작대가 만드는 모든 결과물이 쌓인 상태.
	for r in recipes:
		station.add_to_buffer({"id": r.output.id, "count": 999})
	station.job = {"recipe": recipes[0].id, "left": 999.0, "output": recipes[0].output}
	game.crafting_view().open_station(station, book)
	assert_eq(game.crafting_view().shown_recipes().size(), recipes.size())
	for locale in LOCALES:
		await _set_locale(locale)
		_check_screen(_hud(game), "crafting")
	assert_eq(game.crafting_view().shown_buffer().size(), recipes.size())
