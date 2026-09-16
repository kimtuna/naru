class_name AppearanceCatalog
extends RefCounted
## 캐릭터 외형 항목과 선택지 — 데이터 파일 하나(appearance.json)에서 읽는다.
## 항목이나 선택지를 늘리려면 그 파일만 고친다 (spec/12_ui/menu.md).
## 파일 모양: {"parts": [{"id", "label", "options": [{"id", "label", "color"}]}]}
## label 은 번역 키. color 는 미리보기 색 (없으면 순서로 색을 만든다).

const DEFAULT_PATH := "res://ui/menu/appearance.json"

## 테스트는 다른 파일을 가리키게 바꾼다.
static var path := DEFAULT_PATH

## [{"id", "label", "options": [{"id", "label", "color": Color}]}] — 선택지 없는 항목은 뺀다.
var parts: Array[Dictionary] = []


static func load_default() -> AppearanceCatalog:
	return load_file(path)


static func load_file(file_path: String) -> AppearanceCatalog:
	var catalog := AppearanceCatalog.new()
	var text := FileAccess.get_file_as_string(file_path)
	var data = JSON.parse_string(text) if text != "" else null
	if not (data is Dictionary):
		push_error("appearance: cannot read " + file_path)
		return catalog
	for raw in data.get("parts", []):
		var part := _parse_part(raw)
		if not part.is_empty():
			catalog.parts.append(part)
	return catalog


func part_ids() -> PackedStringArray:
	return PackedStringArray(parts.map(func(p): return p.id))


func option_count(part_index: int) -> int:
	return parts[part_index].options.size()


## 항목마다 첫 선택지를 고른 외형 {항목 id: 선택지 id}.
func default_appearance() -> Dictionary:
	var out := {}
	for part in parts:
		out[part.id] = part.options[0].id
	return out


static func _parse_part(raw) -> Dictionary:
	if not (raw is Dictionary) or str(raw.get("id", "")) == "":
		return {}
	var options: Array[Dictionary] = []
	for opt in raw.get("options", []):
		if opt is Dictionary and str(opt.get("id", "")) != "":
			options.append({
				"id": str(opt.id),
				"label": str(opt.get("label", opt.id)),
				"color": _color(opt.get("color", ""), options.size()),
			})
	if options.is_empty():
		return {}
	return {"id": str(raw.id), "label": str(raw.get("label", raw.id)), "options": options}


static func _color(value, index: int) -> Color:
	var s := str(value)
	if Color.html_is_valid(s):
		return Color.html(s)
	return Color.from_hsv(fmod(index * 0.17, 1.0), 0.6, 0.8)
