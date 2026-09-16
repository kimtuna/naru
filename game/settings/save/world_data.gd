class_name WorldData
extends RefCounted
## 월드(섬) 저장 값. 지형은 시드로 다시 만들고 바뀐 것만 저장한다 (spec/01_settings/save.md).

var name := ""
var world_seed := 0
## 만든 시각 — 유닉스 초.
var created_at := 0
## 채취로 없앤 칸 — Vector2i → true. 섬(IslandMap)이 같은 사전을 나눠 쓴다.
var removed_cells: Dictionary = {}
## 없앤 시각 — Vector2i → 월드 시간(초). 재생 주기를 잰다.
var removed_at: Dictionary = {}
## 월드에서 흐른 게임 시간 (초).
var world_time := 0.0
## 바닥에 떨어진 아이템 — {"id", "count", "pos": Vector2 (월드 픽셀)}.
var drops: Array = []
## 설치한 제작대 — {"id": 제작 장소 id, "cell": Vector2i, "job"?: 진행 중인 제작, "buffer"?: 출력 버퍼}.
var stations: Array = []


static func create(world_name: String, seed_value: int) -> WorldData:
	var w := WorldData.new()
	w.name = world_name
	w.world_seed = seed_value
	w.created_at = int(Time.get_unix_time_from_system())
	return w


func to_dict() -> Dictionary:
	return {
		"name": name,
		"seed": world_seed,
		"created_at": created_at,
		"removed": removed_cells.keys(),
		"removed_at": removed_at.duplicate(),
		"time": world_time,
		"drops": drops.duplicate(true),
		"stations": stations.duplicate(true),
	}


static func from_dict(d: Dictionary) -> WorldData:
	var w := WorldData.new()
	w.name = str(d.get("name", ""))
	w.world_seed = int(d.get("seed", 0))
	w.created_at = int(d.get("created_at", 0))
	var removed = d.get("removed", [])
	if removed is Array:
		for cell in removed:
			if cell is Vector2i:
				w.removed_cells[cell] = true
	var times = d.get("removed_at", {})
	if times is Dictionary:
		for cell in times:
			if cell is Vector2i and w.removed_cells.has(cell) and (times[cell] is float or times[cell] is int):
				w.removed_at[cell] = float(times[cell])
	var t = d.get("time", 0.0)
	w.world_time = float(t) if (t is float or t is int) else 0.0
	var drops = d.get("drops", [])
	if drops is Array:
		for drop in drops:
			if drop is Dictionary and drop.get("id") is String and drop.get("pos") is Vector2:
				w.drops.append(drop.duplicate(true))
	var stations = d.get("stations", [])
	if stations is Array:
		for s in stations:
			if s is Dictionary and s.get("id") is String and s.get("cell") is Vector2i:
				w.stations.append(s.duplicate(true))
	return w
