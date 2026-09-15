class_name HotbarView
extends Control

## 화면 아래에 **늘 떠 있는** 9칸. 열고 닫는 창이 아니다 (GDD D-2c —
## 마인크래프트 · 코어 키퍼 방식). 그래서 `CanvasLayer` 안에 있다: 카메라가
## 움직여도 이 줄은 화면에 못 박혀 있어야 한다.
##
## **자리는 순수 계산이다** (`bar_rect` · `slot_rect`). 앵커로 잡지 않는 이유:
## 앵커는 씬 파일의 글자라서 실행 중에 코드가 옮기면 검사가 못 본다. 함수로 내면
## 헤드리스 단위 검사가 「화면 아래인가 · 9칸이 안 겹치나」를 그대로 물을 수 있고,
## 실측 게이트는 **같은 함수로 구운 픽셀의 어디를 볼지** 정한다.
##
## 그림은 색 네모다 — 플레이어와 같은 프로토타입 범위다 (BACKLOG 머리말).
## **불투명하게 칠한다**: 반투명이면 뒤의 월드 색이 섞여서 「핫바가 거기 그려졌나」를
## 픽셀로 물을 수 없다. 사람 눈에도 움직이는 땅 위의 반투명 칸은 읽기 어렵다.

## 한 칸은 **2칸(32px)** 이다. 타일 1칸이면 든 것이 캐릭터보다 작게 보이고,
## 3칸이면 9칸 줄이 화면 가로의 절반을 먹는다.
const SLOT := PlayerMotion.TILE * 2.0
const GAP := 2.0
const BORDER := 2.0
const MARGIN := 8.0            # 화면 아래 끝에서 띄우는 거리

## 아이템 네모는 칸 안으로 이만큼 들어온다. **바탕이 테두리 안쪽에 남아야**
## 실측 게이트가 「아이템에 안 가리는 점」을 볼 수 있다 (measure_window.gd).
const SWATCH_INSET := 6.0

const BG := Color(0.11, 0.12, 0.15)          # 칸 바탕 — 불투명
const EDGE := Color(0.35, 0.37, 0.42)        # 안 든 칸의 테두리
const EDGE_HELD := Color(0.99, 0.93, 0.78)   # **손에 든 칸**. 플레이어의 코와 같은 색이다
const COUNT := Color(0.96, 0.96, 0.92)

## 무엇을 보여줄 손. 없으면 빈 9칸을 그린다 — 씬만 띄우는 검사가 돌아야 한다.
var hotbar: Hotbar = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_relayout()
	get_viewport().size_changed.connect(_relayout)

func _relayout() -> void:
	var r := bar_rect(get_viewport_rect().size)
	position = r.position
	size = r.size
	queue_redraw()

## 9칸 줄 전체가 차지하는 **화면 좌표** 네모. 가로 가운데 · 세로는 아래 끝에서 MARGIN.
static func bar_rect(screen: Vector2) -> Rect2:
	var w := Hotbar.SLOTS * SLOT + (Hotbar.SLOTS - 1) * GAP
	return Rect2(roundf((screen.x - w) * 0.5), screen.y - MARGIN - SLOT, w, SLOT)

## 줄 안에서 index 번째 칸의 **왼쪽 위 모서리까지의 거리**.
static func slot_offset(index: int) -> Vector2:
	return Vector2(index * (SLOT + GAP), 0.0)

## index 번째 칸의 **화면 좌표** 네모.
static func slot_rect(index: int, screen: Vector2) -> Rect2:
	return Rect2(bar_rect(screen).position + slot_offset(index), Vector2(SLOT, SLOT))

## 이 화면 점 아래의 칸. **없으면 -1** 이다 (회차 44 · 집어서 놓기).
## 자리를 내는 함수 바로 옆에 둔다 — 그리는 자리와 집는 자리가 **같은 한 벌**이라야
## 「보이는 칸과 집히는 칸이 다르다」가 생기지 않는다.
## **테두리도 그 칸이다**: `slot_rect` 는 테두리를 품고, 칸끼리는 안 겹친다
## (`test_bag_view.gd` 가 지킨다) — 그래서 답이 하나다.
static func slot_at(point: Vector2, screen: Vector2) -> int:
	for i in Hotbar.SLOTS:
		if slot_rect(i, screen).has_point(point):
			return i
	return -1

## 아이템 색. **자리표시자다** — 진짜 도감은 월드 오브젝트가 생기는 다음 항목에서 온다
## (BACKLOG P2 「월드 오브젝트 배치」). 그때까지는 아이디에서 결정적으로 뽑는다.
static func item_color(id: StringName) -> Color:
	return Color.from_hsv(float(absi(hash(id)) % 360) / 360.0, 0.55, 0.85)

func _draw() -> void:
	var held := hotbar.selected if hotbar != null else -1
	for i in Hotbar.SLOTS:
		var r := Rect2(slot_offset(i), Vector2(SLOT, SLOT))
		var id: StringName = hotbar.items.ids[i] if hotbar != null else Hotbar.EMPTY
		var amount: int = hotbar.items.amounts[i] if hotbar != null else 0
		draw_slot(self, r, id, amount, EDGE_HELD if i == held else EDGE)

## **칸 하나의 그림.** 핫바와 가방이 **같은 함수**를 쓴다 (회차 40) — 칸을 창마다 따로
## 그리면 같은 물건이 다르게 보이고, 게이트의 탐침 자리가 둘로 갈라져 한쪽만 고치는 날이 온다.
## 그리는 쪽을 인자로 받는 이유도 같다: `CanvasItem` 이면 누구든 이 한 벌을 쓴다.
##
## 테두리를 먼저 통째로 칠하고 안쪽을 바탕으로 덮는다 — `draw_rect` 의 선 두께는
## 모서리에서 안팎으로 반씩 걸쳐서 **픽셀 자리가 모호하다.**
static func draw_slot(on: CanvasItem, slot: Rect2, id: StringName, amount: int, edge: Color) -> void:
	on.draw_rect(slot, edge, true)
	on.draw_rect(slot.grow(-BORDER), BG, true)
	if id == Hotbar.EMPTY:
		return
	on.draw_rect(slot.grow(-SWATCH_INSET), item_color(id), true)
	if amount <= 1:
		return
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var text := str(amount)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	on.draw_string(font, slot.end - Vector2(w + 2.0, 2.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COUNT)
