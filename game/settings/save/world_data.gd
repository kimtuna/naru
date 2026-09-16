class_name WorldData
extends RefCounted
## 월드(섬) 저장 값. 지형은 시드로 다시 만든다 (spec/01_settings/save.md).

var name := ""
var world_seed := 0
## 만든 시각 — 유닉스 초.
var created_at := 0


static func create(world_name: String, seed_value: int) -> WorldData:
	var w := WorldData.new()
	w.name = world_name
	w.world_seed = seed_value
	w.created_at = int(Time.get_unix_time_from_system())
	return w


func to_dict() -> Dictionary:
	return {"name": name, "seed": world_seed, "created_at": created_at}


static func from_dict(d: Dictionary) -> WorldData:
	var w := WorldData.new()
	w.name = str(d.get("name", ""))
	w.world_seed = int(d.get("seed", 0))
	w.created_at = int(d.get("created_at", 0))
	return w
