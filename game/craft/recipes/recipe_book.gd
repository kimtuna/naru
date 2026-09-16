class_name RecipeBook
extends RefCounted
## 레시피 목록 — 데이터 파일 하나(recipes.json)에서 읽는다 (spec/05_craft/recipes.md).
## 레시피를 늘리려면 그 파일만 고친다.
## 파일 모양: {"raw": [원자재 id], "stations": [제작 장소 id],
##   "recipes": [{"id", "station", "time", "inputs": [{"id", "count"}], "output": {"id", "count"}}]}
## station "hand" 는 제작대 없이 맨손으로 만든다 — 빈손 시작의 첫 도구 (spec/04_life/gathering.md).
## time 은 초. 레시피마다 다르지만 아이템 목록이 정해질 때까지 전부 임시 5초다 (crafting-stations.md).

const DEFAULT_PATH := "res://craft/recipes/recipes.json"
const HAND := "hand"
## 원자재에서 결과물까지 가공 단계의 최대 (recipes.md 수치).
const MAX_DEPTH := 3

## 테스트는 다른 파일을 가리키게 바꾼다.
static var path := DEFAULT_PATH

var raw: PackedStringArray = []
var stations: PackedStringArray = []
## [{"id", "station", "time", "inputs": [{"id", "count"}], "output": {"id", "count"}}]
var recipes: Array[Dictionary] = []


static func load_default() -> RecipeBook:
	return load_file(path)


static func load_file(file_path: String) -> RecipeBook:
	var book := RecipeBook.new()
	var text := FileAccess.get_file_as_string(file_path)
	var data = JSON.parse_string(text) if text != "" else null
	if not (data is Dictionary):
		push_error("recipes: cannot read " + file_path)
		return book
	for id in data.get("raw", []):
		book.raw.append(str(id))
	for id in data.get("stations", []):
		book.stations.append(str(id))
	for r in data.get("recipes", []):
		if r is Dictionary:
			book.recipes.append(_parse(r))
	return book


static func _parse(r: Dictionary) -> Dictionary:
	var inputs: Array[Dictionary] = []
	for it in r.get("inputs", []):
		inputs.append(_stack(it))
	return {
		"id": str(r.get("id", "")),
		"station": str(r.get("station", "")),
		"time": float(r.get("time", 0.0)),
		"inputs": inputs,
		"output": _stack(r.get("output", {})),
	}


static func _stack(it) -> Dictionary:
	if not (it is Dictionary):
		return {"id": "", "count": 0}
	return {"id": str(it.get("id", "")), "count": int(it.get("count", 0))}


func get_recipe(id: String) -> Dictionary:
	for r in recipes:
		if r.id == id:
			return r
	return {}


## 이 아이템을 만드는 레시피 (없으면 빈 사전).
func recipe_for(item_id: String) -> Dictionary:
	for r in recipes:
		if r.output.id == item_id:
			return r
	return {}


## 이 장소에서 만드는 레시피들.
func recipes_at(station: String) -> Array[Dictionary]:
	return recipes.filter(func(r): return r.station == station)


func is_raw(item_id: String) -> bool:
	return item_id in raw


## 원자재에서 이 아이템까지 가공 단계 수. 원자재는 0.
## 만들 길이 없거나 순환이면 -1.
func depth_of(item_id: String) -> int:
	return _depth(item_id, {})


func _depth(item_id: String, visiting: Dictionary) -> int:
	if is_raw(item_id):
		return 0
	var r := recipe_for(item_id)
	if r.is_empty() or visiting.has(item_id):
		return -1
	visiting[item_id] = true
	var deepest := 0
	for it in r.inputs:
		var d := _depth(it.id, visiting)
		if d < 0:
			return -1
		deepest = maxi(deepest, d)
	visiting.erase(item_id)
	return deepest + 1


## 가방에 이 레시피의 재료가 다 있나.
func has_materials(recipe: Dictionary, inventory: Inventory) -> bool:
	for it in recipe.get("inputs", []):
		if inventory.count_of(it.id) < it.count:
			return false
	return not recipe.is_empty()
