class_name Hotbar
extends RefCounted

## 손. **핫바 9칸과 「지금 무엇을 들었나」의 순수 계산**이다 — 노드도 엔진도 안 본다.
##
## **가방과 따로 얹은 9칸이다** (GDD D-2c · `Inventory` 머리말). 가방 18칸과 합쳐서
## 27칸을 한 줄로 세지 않는다 — 핫바는 「들 수 있는 것」이고 가방은 「가진 것」이라
## 규칙이 다르다. 칸 계산 자체는 `Inventory` 를 그대로 쓴다: **넘치는 몫이 사라지지
## 않는다**는 불변식이 손에서도 같아야 하기 때문이다.
##
## **손에 든 것은 「고른 칸」이지 「든 물건」이 아니다.** 칸이 비면 맨손이다 —
## 빈 칸을 못 고르게 막으면 맨손으로 돌아갈 길이 없어진다 (GDD D-2c 는 맨손 채집을 쓴다).

const SLOTS := 9        # 사람이 정했다: 숫자키 1..9 한 줄. **0 은 안 쓴다** —
                        # 10번째 칸이 생기면 키가 줄 끝에서 끊긴다 (마인크래프트 · 코어 키퍼)
const EMPTY := Inventory.EMPTY

## 입력 액션 이름의 앞머리. **배선과 계산이 여기 한 곳에서 나온다** —
## project.godot 의 액션 이름을 손으로 적으면 둘이 갈라진다.
const ACTION_PREFIX := "hotbar_"

## 9칸의 내용물. 가방과 **다른 객체**다.
var items: Inventory

## 손에 든 칸. 0 .. SLOTS-1.
var selected := 0

func _init() -> void:
	items = Inventory.new(SLOTS)

func slot_count() -> int:
	return items.slot_count()

## 골라 든다. 돌려주는 것은 **고르고 난 뒤 손에 있는 칸**이다.
##
## **범위 밖이면 손이 안 움직인다** — 감싸지도(wrap) 자르지도(clamp) 않는다.
## 엉뚱한 키 하나가 손을 조용히 옆 칸으로 옮기면, 다음 좌클릭이 딴짓을 하는데
## 사람은 무엇을 눌렀는지 모른다.
func select(index: int) -> int:
	if index >= 0 and index < SLOTS:
		selected = index
	return selected

## 사람이 누른 **숫자** (1..9) 로 고른다. 화면의 1번 칸이 키 1 이다.
func select_by_number(n: int) -> int:
	return select(n - 1)

func held_id() -> StringName:
	return items.ids[selected]

func held_amount() -> int:
	return items.amounts[selected]

## 맨손이다. **「빈 칸을 들었다」와 같은 말이다** — 손은 언제나 어떤 칸을 가리킨다.
func is_empty_handed() -> bool:
	return held_id() == EMPTY

## 칸 → 입력 액션 이름. `project.godot` 의 `hotbar_1` .. `hotbar_9` 와 같은 글자다.
static func action_for(index: int) -> StringName:
	return StringName("%s%d" % [ACTION_PREFIX, index + 1])

## 입력 액션 이름 → 칸. **핫바 액션이 아니면 -1** 이다 (`move_left` · `hotbar_0` · `hotbar_10`).
static func index_for_action(action: StringName) -> int:
	var s := String(action)
	if not s.begins_with(ACTION_PREFIX):
		return -1
	var tail := s.substr(ACTION_PREFIX.length())
	if not tail.is_valid_int():
		return -1
	var n := int(tail)
	return n - 1 if n >= 1 and n <= SLOTS else -1
