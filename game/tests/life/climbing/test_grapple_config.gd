extends GutTest
## G-014 4단계 — 갈고리총 데이터: 등급마다 최대 거리 · 탄창이 있고, 등급마다 레시피가 있다. 최대 거리로 걸리는 지점.

const GUN := "grapple_gun"
const GUN_2 := "grapple_gun_2"


func _cfg_grapple() -> GrappleConfig:
	return GrappleConfig.load_default()


func _gun(id := GUN) -> Dictionary:
	return {"id": id, "count": 1}


func test_grades_have_max_range_and_magazine_in_data() -> void:
	var cfg := _cfg_grapple()
	assert_true(cfg.guns.size() >= 2, "at least two grapple gun grades")
	var ranges := {}
	for id: String in cfg.guns:
		var item := _gun(id)
		assert_true(cfg.is_grapple(item))
		assert_gt(cfg.stat(item, "range_tiles"), 0.0, id + " has a max range")
		assert_gt(cfg.magazine(item), 0, id + " has a magazine")
		ranges[cfg.stat(item, "range_tiles")] = true
	assert_eq(ranges.size(), cfg.guns.size(), "each grade has its own max range")
	assert_gt(cfg.stat(_gun(GUN_2), "range_tiles"), cfg.stat(_gun(GUN), "range_tiles"), "the higher grade reaches farther")
	assert_false(cfg.is_grapple({"id": "gun", "count": 1}))
	assert_false(cfg.is_grapple(null))


func test_every_grade_has_a_recipe_from_raw_materials() -> void:
	var book := RecipeBook.load_default()
	for id: String in _cfg_grapple().guns:
		var r := book.recipe_for(id)
		assert_false(r.is_empty(), "no recipe makes " + id)
		assert_eq(r.output.id, id)
		assert_true(book.stations.has(r.station))
		var d := book.depth_of(id)
		assert_gt(d, 0, id + " cannot be made from raw materials")
		assert_true(d <= RecipeBook.MAX_DEPTH)
		assert_ne(tr("ITEM_" + id.to_upper()), "ITEM_" + id.to_upper(), id + " has a translated name")


func test_hook_point_is_clamped_to_max_range() -> void:
	var from := Vector2(10, 10)
	assert_eq(GrappleConfig.hook_point(from, Vector2(40, 10), 64.0), Vector2(40, 10), "short aim hooks where aimed")
	assert_eq(GrappleConfig.hook_point(from, Vector2(210, 10), 64.0), Vector2(74, 10), "long aim hooks at max range")
	var diag := GrappleConfig.hook_point(from, from + Vector2(300, 400), 50.0)
	assert_almost_eq(diag, from + Vector2(30, 40), Vector2(0.01, 0.01))
