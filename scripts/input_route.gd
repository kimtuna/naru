class_name InputRoute
extends RefCounted

## **창이 열려 있는 동안 어떤 입력이 살아 있나** — 표 하나다. 노드도 엔진도 안 본다.
##
## **가방을 연 채로 걸을 수는 있다** (코어 키퍼 방식): 정리하는 동안 몸이 굳으면
## 사람은 창을 열기를 겁내고, 그러면 가방이 「멈춰서 쓰는 것」이 된다.
## 하지만 **좌클릭은 UI 로 가고 숫자키는 손을 안 바꾼다** — 안 가르면 가방을
## 정리하다 나무를 베고 손이 바뀐다 (GDD D-2c 는 좌클릭 하나로 모든 도구를 쓴다).
## **가방 키 자신은 산다**: 죽으면 한 번 연 창을 못 닫는다.
##
## **왜 클래스가 따로 있나**: 갈래를 `main.gd` 의 `if` 로 흩으면 창이 늘 때마다
## 같은 조건이 `_poll_*` 마다 복사되고, 어느 회차가 한 곳을 빼먹는다 — 그 빼먹음은
## 「가방을 정리하다 손이 바뀐다」로만 보여서 아무 검사도 안 빨개진다.
## 창은 줄을 서 있다: 상자 · 제작대 (GDD D-2c 「여는 것도 좌클릭이다」).
##
## **액션 이름도 여기서 만난다.** 갈래를 적고 액션을 안 적으면 project.godot 에
## 새 입력을 묶는 회차가 그것을 **아무 갈래에도 안 넣은 채** 넘어간다 —
## 그 입력은 창이 열려 있어도 그대로 월드로 간다. `test_input_route.gd` 가
## InputMap 을 훑어서 갈래 없는 액션을 센다.

const MOVE := &"move"
const USE := &"use"
const HOTBAR := &"hotbar"
const BAG := &"bag"

## 입력의 갈래 전부. **여기 적고 아래 표에 안 적으면 `missing()` 이 부른다.**
const KINDS := [MOVE, USE, HOTBAR, BAG]

## **창이 열린 동안 살아 있는 갈래.** 여기 없는 갈래는 창이 먹는다.
const LIVE_WHILE_OPEN := {
	MOVE: true,      # 걸을 수는 있다 — 정리하다 굳으면 창을 열기가 겁난다
	USE: false,      # 좌클릭은 UI 로 간다. 휘두르지 않는다
	HOTBAR: false,   # 숫자키는 손을 안 바꾼다
	BAG: true,       # E 로 닫는다. 이게 죽으면 창이 영영 안 닫힌다
}

## 이동 액션 넷. **순서가 `Input.get_vector` 의 인자 순서다** (왼·오른·위·아래).
const MOVE_ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down"]

## 좌클릭 · 가방 키의 액션 이름. `main.gd` 의 상수가 이것을 가리킨다.
const USE_ACTION := &"use"
const BAG_ACTION := &"bag"

## 이 입력이 지금 살아 있나. **창이 닫혀 있으면 전부 산다.**
##
## **모르는 갈래는 창이 열린 동안 안 산다.** 표에 안 적힌 것이 조용히 월드로 가면
## 이 표가 있는 이유가 없어진다 — 안 적힌 것은 `missing()` 이 이름으로 부른다.
static func is_live(kind: StringName, ui_open: bool) -> bool:
	if not ui_open:
		return true
	return LIVE_WHILE_OPEN.get(kind, false)

## 표가 빠뜨린 갈래. **비어 있어야 한다** (`Claim.missing()` 과 같은 자리).
static func missing() -> Array:
	var out := []
	for kind in KINDS:
		if not LIVE_WHILE_OPEN.has(kind):
			out.append(kind)
	return out

## 갈래 → 그 갈래에 딸린 **입력 액션 이름들.** 핫바 아홉은 `Hotbar` 가 만든다 —
## 글자를 다시 적으면 project.godot 의 배선과 갈라진다.
static func actions_for(kind: StringName) -> Array:
	match kind:
		MOVE:
			return MOVE_ACTIONS.duplicate()
		USE:
			return [USE_ACTION]
		BAG:
			return [BAG_ACTION]
		HOTBAR:
			var out := []
			for i in Hotbar.SLOTS:
				out.append(Hotbar.action_for(i))
			return out
	return []

## 액션 이름 → 갈래. **모르는 액션은 빈 이름**이다 — 갈래가 없는 입력을 세는 자리다.
static func kind_of(action: StringName) -> StringName:
	for kind in KINDS:
		if actions_for(kind).has(action):
			return kind
	return &""
