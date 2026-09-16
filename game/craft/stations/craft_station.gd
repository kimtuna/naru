class_name CraftStation
extends StaticBody2D
## 설치된 제작대 하나 — 한 칸을 차지하고 몸을 막는다 (spec/05_craft/crafting-stations.md).
## 제작은 즉시 끝나지 않는다: 시작하면 재료를 쓰고 타이머가 돌고, 끝나면 결과물이 출력 버퍼에 쌓인다.
## 버퍼는 플레이어가 수령할 때까지 남는다 — 나중에 드론 · 주민이 같은 버퍼에서 꺼내 간다.
## 한 번에 하나만 만든다. 버퍼 최대 칸 수는 spec 미정이라 막지 않는다.

signal craft_started(recipe_id: String)
signal crafted(item: Dictionary)
signal buffer_changed
## 그림은 임시 색 네모다. 아트는 사람이 나중에 넣는다.

## 임시 색 — 제작대 종류마다.
const COLORS := {
	"workbench": Color(0.72, 0.5, 0.25),
}

## 제작 장소 id — 레시피의 station 값이자 설치하는 아이템 id.
var station_id := ""
var cell := Vector2i.ZERO
var tile_px := 16
## 진행 중인 제작 — {"recipe": id, "left": 남은 초, "output": {"id", "count"}}. 없으면 빈 사전.
var job: Dictionary = {}
## 출력 버퍼 — [{"id", "count"}]. 같은 아이템은 한 줄에 합친다.
var buffer: Array[Dictionary] = []


static func create(id: String, at_cell: Vector2i, tile: int) -> CraftStation:
	var s := CraftStation.new()
	s.station_id = id
	s.cell = at_cell
	s.tile_px = tile
	s.name = "Station_%d_%d" % [at_cell.x, at_cell.y]
	s.position = Vector2(at_cell * tile)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile, tile)
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = shape.size / 2.0
	s.add_child(col)
	return s


func is_busy() -> bool:
	return not job.is_empty()


## 진행 중인 제작의 남은 초 (없으면 0).
func time_left() -> float:
	return float(job.get("left", 0.0))


## 이 레시피를 이 제작대에서 시작한다 — 재료를 가방에서 쓴다.
## 다른 제작 중 · 다른 제작대의 레시피 · 재료 부족이면 아무것도 하지 않고 false.
func start(recipe: Dictionary, inventory: Inventory) -> bool:
	if is_busy() or recipe.is_empty() or recipe.get("station") != station_id or inventory == null:
		return false
	for it in recipe.inputs:
		if inventory.count_of(it.id) < it.count:
			return false
	for it in recipe.inputs:
		inventory.remove(it.id, it.count)
	job = {"recipe": recipe.id, "left": maxf(float(recipe.time), 0.0), "output": recipe.output.duplicate()}
	craft_started.emit(recipe.id)
	if time_left() <= 0.0:
		tick(0.0)
	return true


## 타이머를 delta 초 흘린다. 다 되면 결과물을 버퍼에 넣는다.
func tick(delta: float) -> void:
	if not is_busy():
		return
	job["left"] = time_left() - delta
	if time_left() > 0.0:
		return
	var out: Dictionary = job.output
	job = {}
	add_to_buffer(out)
	crafted.emit(out)


func _process(delta: float) -> void:
	tick(delta)


func add_to_buffer(item: Dictionary) -> void:
	var id := str(item.get("id", ""))
	var count := int(item.get("count", 0))
	if id.is_empty() or count <= 0:
		return
	for it in buffer:
		if it.id == id:
			it.count += count
			buffer_changed.emit()
			return
	buffer.append({"id": id, "count": count})
	buffer_changed.emit()


## 버퍼의 이 아이템 개수.
func buffered(id: String) -> int:
	for it in buffer:
		if it.id == id:
			return it.count
	return 0


## 버퍼를 가방으로 옮긴다. 가방에 안 들어가는 몫은 버퍼에 남는다. 옮긴 개수를 돌려준다.
func collect(inventory: Inventory) -> int:
	if inventory == null:
		return 0
	var moved := 0
	var kept: Array[Dictionary] = []
	for it in buffer:
		var left := inventory.add(it.duplicate())
		moved += it.count - left
		if left > 0:
			kept.append({"id": it.id, "count": left})
	if moved > 0:
		buffer = kept
		buffer_changed.emit()
	return moved


## 월드 저장에 넣는 값 — 진행 중인 제작과 버퍼는 있을 때만 넣는다.
func to_dict() -> Dictionary:
	var d := {"id": station_id, "cell": cell}
	if is_busy():
		d["job"] = job.duplicate(true)
	if not buffer.is_empty():
		d["buffer"] = buffer.duplicate(true)
	return d


## 저장 값에서 진행 중인 제작과 버퍼를 되살린다. 모양이 틀린 값은 버린다.
func load_state(d: Dictionary) -> void:
	var j = d.get("job")
	if j is Dictionary and j.get("recipe") is String and (j.get("left") is float or j.get("left") is int) \
			and j.get("output") is Dictionary:
		job = {"recipe": j.recipe, "left": float(j.left),
			"output": {"id": str(j.output.get("id", "")), "count": int(j.output.get("count", 0))}}
	var b = d.get("buffer")
	if b is Array:
		buffer.clear()
		for it in b:
			if it is Dictionary and it.get("id") is String:
				add_to_buffer(it)


func _draw() -> void:
	var t := Vector2(tile_px, tile_px)
	draw_rect(Rect2(Vector2.ONE, t - Vector2.ONE * 2.0), COLORS.get(station_id, Color.MAGENTA))
