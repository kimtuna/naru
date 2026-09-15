class_name BagView
extends Control

## 가방 18칸. **`E` 로 열고 닫는 창**이다 — 늘 떠 있는 핫바와 반대다 (GDD D-2c).
## 그래서 핫바와 같은 `CanvasLayer` 안에 있다: 카메라가 움직여도 창은 화면에 못 박혀 있다.
##
## **핫바 바로 위에 뜬다 — 둘을 같이 본다** (BACKLOG 「가방 18칸과 핫바 9칸을 같이
## 보여준다」). 핫바를 가리면 「무엇을 들었나」를 보면서 가방을 정리할 수 없다.
## **9칸 줄이다**(18 = 2 × 9): 열이 핫바 9칸과 **정확히 같은 x 에** 선다 —
## 「칸 사이로 아이템을 옮긴다」(회차 44)가 위아래로 곧장 오가는 그림이 된다.
##
## **자리는 순수 계산이다** (`panel_rect` · `slot_rect`) — 핫바가 회차 20 에 배운 그대로다.
## 앵커는 씬 파일의 글자라 실행 중에 코드가 옮기면 검사가 못 본다. 함수로 내면
## 같은 함수가 **「어디에 그리나」와 「게이트가 어디를 읽나」를 둘 다** 준다.
##
## **칸 하나의 그림은 `HotbarView.draw_slot` 이다.** 여기서 다시 그리면 두 창의 칸이
## 조용히 달라지고, 게이트의 탐침 자리가 둘로 갈라진다.
##
## **월드를 가린다** — 그래서 `measure_window.gd` 의 BAG 가 **연 채로 구운 픽셀**을
## 판정한다. DRAW 는 닫힌 화면만 보므로 그 구간에는 눈이 없다.

const COLS := 9                       # 핫바 9칸과 같은 열 — 위아래가 줄을 맞춘다
const ROWS := 2                       # 18 = 2 × 9. Inventory.SLOTS 와 맞는지는 검사가 잰다

## 칸의 크기·틈·테두리는 **핫바에서 온다**. 가방 칸만 따로 크면 같은 물건이 창마다
## 다른 크기로 보인다.
const SLOT := HotbarView.SLOT
const GAP := HotbarView.GAP

const PAD := 6.0                      # 칸 격자 둘레의 바탕. 창의 가장자리가 보여야 「창」이다
const LIFT := 8.0                     # 핫바 윗변에서 띄우는 거리

## 창 바탕 — **불투명하다**. 반투명이면 뒤의 월드 색이 섞여서 「가방이 거기 떴나」를
## 픽셀로 못 묻는다 (핫바 머리말과 같은 이유).
const PANEL := Color(0.07, 0.08, 0.10)

## 무엇을 보여줄 가방. 없으면 빈 18칸을 그린다 — 씬만 띄우는 검사가 돌아야 한다.
var inventory: Inventory = null

## **커서가 든 것** (회차 44). 없으면 아무것도 안 그린다.
## 계산은 `Grab` 의 것이고 여기는 **그 무더기를 커서 자리에 그리는 것**만 한다 —
## 손에 든 것이 화면에 안 보이면 사람은 무엇을 집었는지 모르고, 그러면
## 「꽉 찬 칸에 놓아서 남은 몫」도 눈에 안 보인다.
var grab: Grab = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _relayout() -> void:
	var r := panel_rect(get_viewport_rect().size)
	position = r.position
	size = r.size
	queue_redraw()

## 열려 있나. **`visible` 이 곧 상태다** — 따로 bool 을 들면 둘이 어긋나는 날,
## 「열렸다는데 안 보인다」가 된다.
func is_open() -> bool:
	return visible

## 열고 닫는다. 돌려주는 것은 **뒤집고 난 뒤**의 상태다.
##
## **여는 길은 이 하나다.** 밖에서 `visible` 을 직접 만지면 「연다」가 두 곳이 되고,
## 칸의 내용이 바뀌는 다음 항목(집어서 놓기)부터는 다시 그리기를 빠뜨리는 쪽이 생긴다.
## 지금은 보였다 숨는 것만으로도 엔진이 다시 그리므로 **`queue_redraw()` 는 대조군이
## 안 잡는다** (2026-09-16 · 빼도 `ALL GREEN`) — 그래도 남긴다: 다음 항목이 쓸 줄이다.
func toggle() -> bool:
	visible = not visible
	queue_redraw()
	return visible

## 칸 격자만의 크기(창 바탕 제외).
static func grid_size() -> Vector2:
	return Vector2(COLS * SLOT + (COLS - 1) * GAP, ROWS * SLOT + (ROWS - 1) * GAP)

## 창 전체가 차지하는 **화면 좌표** 네모. 가로 가운데 · **핫바 바로 위**.
## 핫바의 자리에서 내므로 둘 중 하나만 움직이는 일이 없다.
static func panel_rect(screen: Vector2) -> Rect2:
	var g := grid_size() + Vector2.ONE * (PAD * 2.0)
	var bar := HotbarView.bar_rect(screen)
	return Rect2(roundf((screen.x - g.x) * 0.5), bar.position.y - LIFT - g.y, g.x, g.y)

## 창 안에서 index 번째 칸의 **왼쪽 위 모서리까지의 거리**. 0번이 왼쪽 위다.
static func slot_offset(index: int) -> Vector2:
	var col := index % COLS
	var row := index / COLS
	return Vector2(PAD + col * (SLOT + GAP), PAD + row * (SLOT + GAP))

## index 번째 칸의 **화면 좌표** 네모.
static func slot_rect(index: int, screen: Vector2) -> Rect2:
	return Rect2(panel_rect(screen).position + slot_offset(index), Vector2(SLOT, SLOT))

## 이 화면 점 아래의 칸. **없으면 -1** 이다 (회차 44 · 집어서 놓기).
## 핫바의 같은 이름과 **한 벌**이다 — 창이 둘이라 답하는 곳도 둘이지만,
## 「어느 창이냐」를 가르는 것은 `main.gd` 한 곳뿐이다.
static func slot_at(point: Vector2, screen: Vector2) -> int:
	for i in Inventory.SLOTS:
		if slot_rect(i, screen).has_point(point):
			return i
	return -1

## **커서를 따라가야 하므로 매 프레임 다시 그린다** — 든 것이 있을 때만.
## 빈 손일 때까지 돌리면 아무것도 안 변하는 화면을 60Hz 로 다시 칠한다.
func _process(_delta: float) -> void:
	if visible and grab != null and not grab.is_empty():
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL, true)
	for i in Inventory.SLOTS:
		var r := Rect2(slot_offset(i), Vector2(SLOT, SLOT))
		var id: StringName = inventory.ids[i] if inventory != null else Inventory.EMPTY
		var amount: int = inventory.amounts[i] if inventory != null else 0
		# **고른 칸이 없다.** 손은 핫바의 것이라 여기서 강조하면 「어느 것을 들었나」가
		# 화면에 두 개 생긴다. 집어서 놓기(회차 44)는 **커서를 따라다니는 제 표시**를
		# 쓴다 (`_draw_grab`) — 칸을 강조하지 않는다.
		HotbarView.draw_slot(self, r, id, amount, HotbarView.EDGE)
	_draw_grab()

## 커서가 든 무더기를 **커서 한가운데**에 그린다. 칸 하나와 같은 그림이고
## 테두리만 `EDGE_HELD` 다 — 「이건 칸이 아니라 손에 있는 것」이 한눈에 읽혀야 한다.
##
## **창 네모 밖으로 나간다** — Control 은 기본으로 안 자르므로 커서가 핫바 위에
## 있어도 그려진다. 여기서 그리는 이유는 **가방보다 뒤**라서다: 든 것이 칸 아래로
## 들어가면 무엇을 집었는지 안 보인다.
func _draw_grab() -> void:
	if grab == null or grab.is_empty():
		return
	var c := get_local_mouse_position()
	HotbarView.draw_slot(self, Rect2(c - Vector2.ONE * (SLOT * 0.5), Vector2(SLOT, SLOT)),
		grab.id, grab.amount, HotbarView.EDGE_HELD)
