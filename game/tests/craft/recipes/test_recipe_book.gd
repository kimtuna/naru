extends GutTest
## G-006 1단계 — 레시피 데이터.
## 레시피는 데이터 파일에 있고, 어떤 결과물도 원자재에서 가공 단계가 3 이하다.
## 첫 도구(도끼 또는 곡괭이)는 제작대 없이 맨손으로 만들 수 있다.

const REQUIRED := ["axe", "pickaxe", "gun", "workbench", "ammo"]
const TMP_PATH := "user://test_recipes_tmp.json"

var book: RecipeBook


func before_each() -> void:
	book = RecipeBook.load_default()


func after_each() -> void:
	RecipeBook.path = RecipeBook.DEFAULT_PATH
	if FileAccess.file_exists(TMP_PATH):
		DirAccess.remove_absolute(TMP_PATH)


func _write_tmp(data: Dictionary) -> RecipeBook:
	var f := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	return RecipeBook.load_file(TMP_PATH)


func _r(id: String, station: String, inputs: Array) -> Dictionary:
	var list := inputs.map(func(i): return {"id": i, "count": 1})
	return {"id": id, "station": station, "time": 5.0, "inputs": list, "output": {"id": id, "count": 1}}


# --- 데이터 파일 ---

func test_recipes_live_in_a_data_file() -> void:
	assert_true(FileAccess.file_exists(RecipeBook.DEFAULT_PATH), "recipe data file missing")
	var data = JSON.parse_string(FileAccess.get_file_as_string(RecipeBook.DEFAULT_PATH))
	assert_true(data is Dictionary, "recipe file must be JSON object")
	assert_eq(book.recipes.size(), data.get("recipes", []).size(), "every recipe in the file is loaded")
	var src := FileAccess.get_file_as_string("res://craft/recipes/recipe_book.gd")
	for id in REQUIRED:
		assert_false(src.contains('"%s"' % id), "recipe %s must not be hard-coded in code" % id)


func test_required_items_have_recipes() -> void:
	for id in REQUIRED:
		assert_false(book.recipe_for(id).is_empty(), "no recipe makes " + id)


func test_recipe_entries_are_well_formed() -> void:
	assert_gt(book.recipes.size(), 0)
	assert_true(book.stations.has(RecipeBook.HAND), "hand must be a station")
	var ids := {}
	var outputs := {}
	for r in book.recipes:
		assert_ne(r.id, "", "recipe without id")
		assert_false(ids.has(r.id), "duplicate recipe id " + r.id)
		ids[r.id] = true
		assert_true(book.stations.has(r.station), "%s: unknown station %s" % [r.id, r.station])
		assert_gt(r.time, 0.0, r.id + ": time must be positive")
		assert_gt(r.inputs.size(), 0, r.id + ": needs inputs")
		for it in r.inputs:
			assert_ne(it.id, "", r.id + ": input without id")
			assert_gt(it.count, 0, r.id + ": input count must be positive")
		assert_ne(r.output.id, "", r.id + ": output without id")
		assert_gt(r.output.count, 0, r.id + ": output count must be positive")
		assert_false(book.is_raw(r.output.id), r.id + ": raw material must not be crafted")
		assert_false(outputs.has(r.output.id), "two recipes make " + r.output.id)
		outputs[r.output.id] = true


func test_raw_materials_come_from_harvesting() -> void:
	var drops := HarvestConfig.DROPS.values()
	assert_gt(book.raw.size(), 0)
	for id in book.raw:
		assert_has(drops, id, "raw %s cannot be harvested" % id)


# --- 가공 단계 3 이하 ---

func test_every_output_is_at_most_three_steps_from_raw() -> void:
	assert_eq(RecipeBook.MAX_DEPTH, 3)
	for r in book.recipes:
		var d := book.depth_of(r.output.id)
		assert_gt(d, 0, "%s: cannot be made from raw materials (depth %d)" % [r.output.id, d])
		assert_true(d <= RecipeBook.MAX_DEPTH, "%s: %d steps from raw (max 3)" % [r.output.id, d])


func test_depth_counts_processing_steps() -> void:
	var b := _write_tmp({"raw": ["wood"], "stations": ["hand"], "recipes": [
		_r("a", "hand", ["wood"]), _r("b", "hand", ["a", "wood"]),
		_r("c", "hand", ["b"]), _r("d", "hand", ["c", "a"]),
	]})
	assert_eq(b.depth_of("wood"), 0)
	assert_eq(b.depth_of("a"), 1)
	assert_eq(b.depth_of("b"), 2)
	assert_eq(b.depth_of("c"), 3)
	assert_eq(b.depth_of("d"), 4, "a 4-step item must be caught")
	assert_true(b.depth_of("d") > RecipeBook.MAX_DEPTH)


func test_depth_rejects_unmakeable_and_cycles() -> void:
	var b := _write_tmp({"raw": ["wood"], "stations": ["hand"], "recipes": [
		_r("x", "hand", ["missing"]), _r("p", "hand", ["q"]), _r("q", "hand", ["p"]),
	]})
	assert_eq(b.depth_of("x"), -1, "input nobody makes")
	assert_eq(b.depth_of("p"), -1, "cycle")
	assert_eq(b.depth_of("nothing"), -1, "no recipe")


func test_path_can_point_at_another_file() -> void:
	_write_tmp({"raw": ["wood"], "stations": ["hand"], "recipes": [_r("only", "hand", ["wood"])]})
	RecipeBook.path = TMP_PATH
	var b := RecipeBook.load_default()
	assert_eq(b.recipes.size(), 1)
	assert_eq(b.get_recipe("only").station, "hand")


# --- 빈손 시작: 첫 도구는 맨손 제작 ---

func test_first_tool_is_hand_craftable_from_bare_hand_drops() -> void:
	var hand_drops := HarvestConfig.harvestable_by(HarvestConfig.HAND).map(func(d): return HarvestConfig.DROPS[d])
	var ok := []
	for tool in [HarvestConfig.AXE, HarvestConfig.PICKAXE]:
		var r := book.recipe_for(str(tool))
		if r.is_empty() or r.station != RecipeBook.HAND:
			continue
		var all_hand := true
		for it in r.inputs:
			if not hand_drops.has(it.id):
				all_hand = false
		if all_hand:
			ok.append(tool)
	assert_gt(ok.size(), 0, "axe or pickaxe must be hand-craftable from bare-hand drops only")
	assert_true(book.recipes_at(RecipeBook.HAND).any(func(r): return r.output.id in ok))


func test_fresh_character_can_gather_then_has_materials_for_first_tool() -> void:
	var inv := Inventory.new(CharacterData.new())
	var axe := book.recipe_for("axe")
	var pickaxe := book.recipe_for("pickaxe")
	assert_eq(inv.count_of("axe") + inv.count_of("pickaxe"), 0, "new game starts without tools")
	assert_false(book.has_materials(axe, inv), "empty bag cannot craft")
	# 맨손 채취로 얻는 것만 넣는다.
	for d in HarvestConfig.harvestable_by(HarvestConfig.HAND):
		inv.add({"id": HarvestConfig.DROPS[d], "count": 20})
	var craftable := [axe, pickaxe].filter(
		func(r): return r.station == RecipeBook.HAND and book.has_materials(r, inv))
	assert_gt(craftable.size(), 0, "bare-hand materials must be enough for a first tool without a bench")


func test_has_materials_checks_counts() -> void:
	var inv := Inventory.new(CharacterData.new())
	var axe := book.recipe_for("axe")
	for it in axe.inputs:
		inv.add({"id": it.id, "count": it.count - 1})
	assert_false(book.has_materials(axe, inv), "one short of each")
	for it in axe.inputs:
		inv.add({"id": it.id, "count": 1})
	assert_true(book.has_materials(axe, inv), "exact amount")
	assert_false(book.has_materials({}, inv), "no recipe")


func test_workbench_itself_is_hand_craftable() -> void:
	# 제작대가 제작대를 요구하면 제작대 레시피가 영영 열리지 않는다.
	var r := book.recipe_for("workbench")
	assert_eq(r.station, RecipeBook.HAND)
	assert_true(book.recipes.any(func(x): return x.station == "workbench"), "some recipe needs the bench")
