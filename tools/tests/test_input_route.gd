extends TestBase

## **창이 열려 있는 동안 어떤 입력이 사나** — 순수한 표 하나를 잰다 (`InputRoute`).
##
## 여기서 재는 것은 **표와 배선**이다. 「`main.gd` 가 그 표를 실제로 묻나」는
## 단위 검사로 못 본다 — `measure_focus.gd` 의 FOCUS 가 진짜 씬에 키를 눌러서 잰다.

const MAIN := "res://scripts/main.gd"

## `ui_*` 는 엔진이 기본으로 묶는 것이다 (`ui_accept` · `ui_cancel` …).
## 우리가 묶은 것이 아니라 갈래를 물을 자리가 아니다.
const ENGINE_PREFIX := "ui_"

func test_창이_닫혀_있으면_다섯_갈래가_다_산다() -> void:
	for kind in InputRoute.KINDS:
		check(InputRoute.is_live(kind, false),
			"창이 닫혀 있으면 %s 는 살아 있어야 한다" % kind)

func test_가방이_열려_있으면_이동과_가방키만_산다() -> void:
	# **걸을 수는 있다** (코어 키퍼 방식): 정리하다 몸이 굳으면 창을 열기가 겁난다.
	check(InputRoute.is_live(InputRoute.MOVE, true), "가방이 열려도 걸을 수 있어야 한다")
	# **가방 키는 산다** — 죽으면 한 번 연 창을 못 닫는다.
	check(InputRoute.is_live(InputRoute.BAG, true), "가방이 열려도 E 로 닫을 수 있어야 한다")
	# **좌클릭과 숫자키는 죽는다**: 정리하다 나무를 베고 손이 바뀐다.
	check(not InputRoute.is_live(InputRoute.USE, true),
		"가방이 열려 있으면 좌클릭은 휘두르지 않아야 한다 (UI 로 간다)")
	check(not InputRoute.is_live(InputRoute.HOTBAR, true),
		"가방이 열려 있으면 숫자키가 손을 바꾸지 않아야 한다")
	# **우클릭도 UI 로 간다** (회차 46): 반을 집고 한 개씩 놓는다.
	check(not InputRoute.is_live(InputRoute.USE_ALT, true),
		"가방이 열려 있으면 우클릭은 UI 로 가야 한다 (반 집기 · 한 개씩 놓기)")

func test_표가_갈래를_다_덮는다() -> void:
	# `Claim.missing()` 과 같은 자리 — 갈래를 적고 표에 안 적은 것을 이름으로 부른다.
	eq(InputRoute.missing(), [], "표가 빠뜨린 갈래")
	# 거꾸로도 본다: 표에만 있고 `KINDS` 에 없는 줄은 아무도 안 묻는 죽은 줄이다.
	for kind in InputRoute.LIVE_WHILE_OPEN:
		check(InputRoute.KINDS.has(kind),
			"표의 %s 가 KINDS 에 없다 — 아무도 묻지 않는 줄이다" % kind)

func test_모르는_갈래는_창이_열리면_안_산다() -> void:
	# **안 적힌 것이 조용히 월드로 가면 이 표가 있는 이유가 없어진다.**
	check(not InputRoute.is_live(&"우클릭", true),
		"표에 없는 갈래는 창이 열린 동안 살면 안 된다")
	check(InputRoute.is_live(&"우클릭", false), "창이 닫혀 있으면 전부 산다")

func test_묶인_입력_액션마다_갈래가_있다() -> void:
	# **이 검사가 회차 46 을 막았다**: project.godot 에 우클릭(반 집기)을 묶으면서
	# 갈래를 안 적으면, 그 입력은 가방이 열려 있어도 그대로 월드로 간다.
	for action in InputMap.get_actions():
		if String(action).begins_with(ENGINE_PREFIX):
			continue
		check(InputRoute.kind_of(action) != &"",
			"입력 액션 %s 가 어느 갈래에도 없다 — InputRoute 에 적어라" % action)

func test_갈래마다_묶인_액션이_있다() -> void:
	for kind in InputRoute.KINDS:
		var actions := InputRoute.actions_for(kind)
		check(not actions.is_empty(), "갈래 %s 에 딸린 액션이 없다" % kind)
		for action in actions:
			check(InputMap.has_action(action),
				"%s 의 액션 %s 가 project.godot 에 없다" % [kind, action])
			eq(InputRoute.kind_of(action), kind, "액션 %s 의 갈래" % action)

func test_main_이_쓰는_액션_이름이_갈래_표에서_온다() -> void:
	# `main.gd` 가 제 글자를 따로 적으면 「배선은 맞는데 갈래에 안 적힌 입력」이 생긴다.
	var m: Dictionary = load(MAIN).get_script_constant_map()
	eq(InputRoute.kind_of(m["USE_ACTION"]), InputRoute.USE, "main.USE_ACTION 의 갈래")
	eq(InputRoute.kind_of(m["USE_ALT_ACTION"]), InputRoute.USE_ALT, "main.USE_ALT_ACTION 의 갈래")
	eq(InputRoute.kind_of(m["BAG_ACTION"]), InputRoute.BAG, "main.BAG_ACTION 의 갈래")

func test_좌클릭과_우클릭은_다른_액션이다() -> void:
	# 둘이 같은 글자면 우클릭을 누를 때마다 휘두르기가 같이 나간다 —
	# 그런데 **갈래 표는 여전히 초록**이라 (둘 다 죽어 있다) 여기가 그 자리다.
	check(InputRoute.USE_ACTION != InputRoute.USE_ALT_ACTION,
		"좌클릭과 우클릭의 액션 이름이 같다")
	var l: Array = InputMap.action_get_events(InputRoute.USE_ACTION)
	var r: Array = InputMap.action_get_events(InputRoute.USE_ALT_ACTION)
	check(l.size() == 1 and l[0] is InputEventMouseButton,
		"%s 는 마우스 버튼 하나여야 한다" % InputRoute.USE_ACTION)
	check(r.size() == 1 and r[0] is InputEventMouseButton,
		"%s 는 마우스 버튼 하나여야 한다" % InputRoute.USE_ALT_ACTION)
	eq((l[0] as InputEventMouseButton).button_index, MOUSE_BUTTON_LEFT, "use 의 버튼")
	eq((r[0] as InputEventMouseButton).button_index, MOUSE_BUTTON_RIGHT, "use_alt 의 버튼")

func test_이동_액션_넷이_get_vector_순서다() -> void:
	# `player.gd` 가 `Input.get_vector(왼, 오른, 위, 아래)` 로 읽는다 — 순서가 뒤집히면
	# 「W 를 눌렀는데 아래로 간다」가 된다. 표가 그 순서를 들고 있어야 쓸 수 있다.
	eq(InputRoute.MOVE_ACTIONS,
		[&"move_left", &"move_right", &"move_up", &"move_down"], "이동 액션 순서")
