class_name InputActions
extends RefCounted
## 입력 액션 이름을 한 곳에 모은다 — 키 배치는 project.godot 의 InputMap 이 정한다.
## 게임 코드는 키 코드 대신 여기 이름을 쓴다 (spec/01_settings/input.md).

const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
## 좌클릭 — 도구 사용 · 상호작용 · 열기를 하나로.
const USE := &"use"
## 가방 화면 열기 · 닫기 — 키는 spec 미정, 임시로 Tab.
const INVENTORY := &"inventory"
const HOTBAR_PREFIX := "hotbar_"
## 숫자키 1~9, 0 을 hotbar_1 ~ hotbar_10 에 묶었다. 핫바 칸 수는 미정 — 핫바가 이 안에서 쓴다.
const HOTBAR_ACTION_COUNT := 10


## 이동 입력 — 길이 1 이하 (대각선도 1). 정규화는 Input.get_vector 가 한다.
static func move_vector() -> Vector2:
	return Input.get_vector(MOVE_LEFT, MOVE_RIGHT, MOVE_UP, MOVE_DOWN)


## 핫바 N번 슬롯(1부터) 선택 액션 이름.
static func hotbar_action(slot: int) -> StringName:
	return StringName(HOTBAR_PREFIX + str(slot))


## 이 입력이 핫바 선택을 눌렀으면 슬롯 번호(1부터), 아니면 0.
static func hotbar_slot_pressed(event: InputEvent) -> int:
	for slot in range(1, HOTBAR_ACTION_COUNT + 1):
		if event.is_action_pressed(hotbar_action(slot)):
			return slot
	return 0


## 게임이 쓰는 액션 이름 전부.
static func all() -> Array[StringName]:
	var names: Array[StringName] = [MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT, USE, INVENTORY]
	for slot in range(1, HOTBAR_ACTION_COUNT + 1):
		names.append(hotbar_action(slot))
	return names
