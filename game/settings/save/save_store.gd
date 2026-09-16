class_name SaveStore
extends RefCounted
## 캐릭터와 월드를 따로 저장한다.
## 캐릭터는 슬롯(0 ~ CHARACTER_SLOTS-1), 월드는 id(파일 이름)로 찾는다.
## 파일은 Godot 바이너리 Variant — 객체는 풀지 않는다 (남이 준 파일도 안전).

var root: String


func _init(root_path: String = SaveConfig.DEFAULT_ROOT) -> void:
	root = root_path


# --- 캐릭터 ---

## 빈 슬롯 하나에 새 캐릭터를 넣는다. 들어간 슬롯, 다 찼으면 -1.
func create_character(data: CharacterData) -> int:
	for slot in SaveConfig.CHARACTER_SLOTS:
		if not has_character(slot):
			return slot if save_character(slot, data) == OK else -1
	return -1


## 슬롯에 저장한다 (있는 캐릭터면 덮어쓴다).
func save_character(slot: int, data: CharacterData) -> Error:
	if not _valid_slot(slot):
		return ERR_PARAMETER_RANGE_ERROR
	return _write(_character_path(slot), data.to_dict())


func load_character(slot: int) -> CharacterData:
	if not has_character(slot):
		return null
	var d = _read(_character_path(slot))
	return CharacterData.from_dict(d) if d is Dictionary else null


func has_character(slot: int) -> bool:
	return _valid_slot(slot) and FileAccess.file_exists(_character_path(slot))


func delete_character(slot: int) -> Error:
	if not has_character(slot):
		return ERR_DOES_NOT_EXIST
	return DirAccess.remove_absolute(_character_path(slot))


## 찬 슬롯 번호들.
func character_slots() -> Array[int]:
	var out: Array[int] = []
	for slot in SaveConfig.CHARACTER_SLOTS:
		if has_character(slot):
			out.append(slot)
	return out


# --- 월드 ---

## 새 월드를 저장하고 id 를 돌려준다. 실패하면 "".
func create_world(data: WorldData) -> String:
	var id := _new_world_id()
	return id if save_world(id, data) == OK else ""


func save_world(id: String, data: WorldData) -> Error:
	if not id.is_valid_filename() or id.is_empty():
		return ERR_INVALID_PARAMETER
	return _write(_world_path(id), data.to_dict())


func load_world(id: String) -> WorldData:
	if not has_world(id):
		return null
	var d = _read(_world_path(id))
	return WorldData.from_dict(d) if d is Dictionary else null


func has_world(id: String) -> bool:
	return id.is_valid_filename() and not id.is_empty() and FileAccess.file_exists(_world_path(id))


func delete_world(id: String) -> Error:
	if not has_world(id):
		return ERR_DOES_NOT_EXIST
	return DirAccess.remove_absolute(_world_path(id))


func world_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var dir := root.path_join(SaveConfig.WORLD_DIR)
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(SaveConfig.FILE_EXT):
			out.append(file.trim_suffix(SaveConfig.FILE_EXT))
	out.sort()
	return out


# --- 내부 ---

func _valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SaveConfig.CHARACTER_SLOTS


func _character_path(slot: int) -> String:
	return root.path_join(SaveConfig.CHARACTER_DIR).path_join("slot_%d%s" % [slot, SaveConfig.FILE_EXT])


func _world_path(id: String) -> String:
	return root.path_join(SaveConfig.WORLD_DIR).path_join(id + SaveConfig.FILE_EXT)


func _new_world_id() -> String:
	var id := ""
	while id.is_empty() or has_world(id):
		id = "world_%d_%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]
	return id


func _write(path: String, payload: Dictionary) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		return err
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_var({"version": SaveConfig.FORMAT_VERSION, "data": payload}, false)
	file.close()
	return OK


func _read(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var wrapped = file.get_var(false)
	if not (wrapped is Dictionary) or not wrapped.has("data"):
		return null
	return wrapped["data"]
