class_name Display
extends RefCounted

## **화면에 붙이는 법.** 논리 화면 960×540 을 실제 화면에 얼마나 키워 붙일지 정한다.
##
## **셋 중 둘만 고를 수 있다** — 로 알았던 것이 틀렸다 (회차 33):
##   ⓐ 띠 없음 · ⓑ 정수 배율 · ⓒ 누구나 같은 범위를 본다
## **셋이 다 된다. 창 크기를 우리가 정하면 된다.** 앞 회차는 「화면 크기가 고정」이라고
## 두고 풀어서 ⓐ 를 버렸는데, 고정인 것은 **전체 화면일 때뿐**이었다.
## ⓒ 는 GDD 의 「해상도가 시야 이득이 되면 안 된다」이고 PvP 가 있어서 못 버린다.
## ⓑ 를 버리면 도트 하나가 화면에서 어떤 건 3px, 어떤 건 4px 이 되어 걸을 때 얼룩이 흐른다.
##
## **띠가 생기는 이유는 창이 게임보다 크기 때문이다.** 그러면 창을 게임에 맞추면 된다 —
## 쓸 수 있는 화면에 들어가는 최대 정수 배율 N 을 구해 창을 정확히 `논리 × N` 으로 잡는다.
## 그리는 크기는 전체 화면과 **한 픽셀도 다르지 않다**(같은 N). 전체 화면이 더 준 것은
## 검은 테두리뿐이었다 (2026-09-15 실측: 576×548 px · NUMBERS 1b).
##
## **여기 숫자가 하나도 없다.** 논리 화면은 project.godot 에서, 쓸 수 있는 화면은
## DisplayServer 에서 온다 — 3456 이든 1920 이든 같은 식이 돈다.
##
## **왜 `screen_get_usable_rect()` 인가**: 전체 화면으로 띄운 창의 크기가 **정확히
## 이 값이었다** (2026-09-15 실측: 화면 3456×2234 · 쓸 수 있는 곳 (0,66)+3456×2168 ·
## 전체 화면 창 (0,66)+3456×2168). macOS 는 메뉴 막대와 노치가 있는 띠를 안 준다 —
## `screen_get_size()` 로 재면 세로를 66px 더 크게 보고 띠를 그만큼 틀리게 적는다.
##
## **`window_get_size()` 를 믿지 마라** (BACKLOG 의 함정): 창 모드에서 요청값을 그대로
## 돌려준다. 실제로 그려진 배율은 `root.get_final_transform()` 에만 있다.

## 논리 화면 — project.godot 의 글자. **여기 다시 적지 않는다** (한 곳에서 만난다).
static func logical() -> Vector2i:
	return Vector2i(
		int(ProjectSettings.get_setting("display/window/size/viewport_width")),
		int(ProjectSettings.get_setting("display/window/size/viewport_height")))

## 쓸 수 있는 화면에 `logical` 을 **정수배로** 넣을 때 가장 큰 배율.
## 인자 이름이 `avail_size` 인 것은 정적 함수 `avail()` 과 겹치지 않으려는 것이다 —
## `avail` 로 두면 함수를 가려서, 안에서 `avail()` 을 부르려다 인자를 부른다.
## 정수 나눗셈이 곧 내림이다. 화면이 논리보다 작아도 1 밑으로는 안 내려간다 —
## 0 배는 아무것도 안 그리는 것이고, 그건 띠가 아니라 고장이다.
static func max_scale(avail_size: Vector2i, logical_size: Vector2i) -> int:
	if logical_size.x <= 0 or logical_size.y <= 0:
		return 1
	if avail_size.x <= 0 or avail_size.y <= 0:
		return 1
	return maxi(1, mini(avail_size.x / logical_size.x, avail_size.y / logical_size.y))

## 그 배율로 실제로 그려지는 크기(px).
static func drawn(avail_size: Vector2i, logical_size: Vector2i) -> Vector2i:
	return logical_size * max_scale(avail_size, logical_size)

## **남는 띠**(px) — 가로·세로 **합**이다. 한쪽에 절반씩 붙는다.
## **무엇을 넣느냐가 뜻을 정한다**: 화면을 넣으면 「전체 화면이면 얼마가 남나」고,
## **창을 넣으면 「사람이 보는 띠」**다. 회차 33 부터 게이트가 재는 것은 뒤쪽이고,
## `fit_size()` 를 넣으면 **언제나 0 이다** — 그게 이 회차가 만든 것이다.
static func bars(avail_size: Vector2i, logical_size: Vector2i) -> Vector2i:
	return avail_size - drawn(avail_size, logical_size)

## **어느 축이 배율을 묶나.** 「세로 띠가 크니 배율을 올리자」로 오는 다음 회차가
## 여기서 멈춘다 — `aspect=keep` 은 배율이 하나라서, 가로가 묶으면 세로를 아무리
## 늘려도 배율이 안 오른다. 반대쪽 띠는 **화면 비율이 16:9 에서 먼 만큼** 남는 것이지
## 덜 줄인 것이 아니다 (2026-09-15: 3456×2168 은 1.594 대 1.778 이라 세로가 548 남는다).
static func binding_axis(avail_size: Vector2i, logical_size: Vector2i) -> String:
	var s := max_scale(avail_size, logical_size)
	var tight_x: bool = avail_size.x - logical_size.x * s < logical_size.x
	var tight_y: bool = avail_size.y - logical_size.y * s < logical_size.y
	if tight_x and tight_y:
		return "둘 다"
	return "가로" if tight_x else "세로"

## 헤드리스인가. **창을 못 띄우는 드라이버에서는 아무것도 만지지 않는다** —
## 화면 크기가 (0,0) 이라 배율이 엉뚱해지고, 단위 검사 한 판이 통째로 흔들린다.
static func has_screen() -> bool:
	return DisplayServer.get_name() != "headless"

## 창을 놓을 수 있는 자리와 크기. **자리까지 있어야 가운데로 놓는다** —
## macOS 의 쓸 수 있는 곳은 (0,0) 이 아니라 (0,66) 에서 시작한다(메뉴 막대).
static func avail_rect() -> Rect2i:
	if not has_screen():
		return Rect2i()
	return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())

## 지금 이 기계에서 쓸 수 있는 화면의 크기.
static func avail() -> Vector2i:
	return avail_rect().size

## **창을 이 크기로 잡는다** — 논리 × 최대 정수 배율. 띠가 0 인 유일한 크기다.
static func fit_size() -> Vector2i:
	return drawn(avail(), logical())

## **창을 게임 크기에 맞춘다.** 배율을 코드가 거는 게 아니다 — `stretch/scale_mode=integer`
## 가 창 크기에서 제가 내림한다. 창을 정확히 `논리 × N` 으로 주면 그 내림이 **딱 N 이라
## 버릴 것이 없다.** 게이트는 「엔진이 실제로 건 배율」과 맞대 본다 (measure_window.gd 의 VIEW).
##
## **전체 화면이 아니라 창이다** (회차 33 에 뒤집었다): 전체 화면은 창 크기를 화면이
## 정해서 3456 ÷ 960 = 3.6 의 소수점 아래가 통째로 띠가 된다. 창은 우리가 정한다.
##
## **가운데로 놓는다.** 안 놓으면 macOS 가 왼쪽 위에 붙여서, 띠는 0 인데 화면 한쪽으로
## 쏠린 창이 뜬다 — 사람 눈에는 그것도 「화면이 안 맞는다」이다.
static func fit_window(w: Window) -> void:
	if not has_screen() or w == null:
		return
	var rect := avail_rect()
	var size := drawn(rect.size, logical())
	w.mode = Window.MODE_WINDOWED
	w.size = size
	w.position = rect.position + (rect.size - size) / 2

## 사람이 읽는 한 줄. 「창 = 논리 × 정수배」와 「남는 띠」를 같이 낸다 —
## 둘 중 하나만 내면 「배율은 맞는데 화면이 안 맞는다」를 아무도 못 본다.
## **띠는 창 기준이다** — 화면 기준으로 내면 창 모드에서는 「바탕 화면이 보인다」를
## 띠라고 적는 꼴이 된다. 같이 내는 `화면 남음` 이 그 수다.
static func report() -> String:
	var lg := logical()
	var av := avail()
	var s := max_scale(av, lg)
	var win := drawn(av, lg)
	var b := bars(win, lg)
	var rest := av - win
	return "DISPLAY 쓸 수 있는 화면 %dx%d · 논리 %dx%d · 배율 %dx · 창 %dx%d · 띠 %dx%d · 화면 남음 %dx%d · 묶는 축 %s" % [
		av.x, av.y, lg.x, lg.y, s, win.x, win.y, b.x, b.y, rest.x, rest.y,
		binding_axis(av, lg)]
