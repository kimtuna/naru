class_name Display
extends RefCounted

## **화면에 붙이는 법.** 논리 화면 960×540 을 실제 화면에 얼마나 키워 붙일지 정한다.
##
## **셋 중 둘만 고를 수 있다** (BACKLOG · 사람이 2026-09-15 에 골랐다):
##   ⓐ 띠 없음 · ⓑ 정수 배율 · ⓒ 누구나 같은 범위를 본다
## **ⓑ + ⓒ 다.** ⓒ 는 GDD 의 「해상도가 시야 이득이 되면 안 된다」이고 PvP 가 있어서
## 못 버린다. ⓑ 를 버리면 도트 하나가 화면에서 어떤 건 3px, 어떤 건 4px 이 되어
## 걸을 때 얼룩이 흐른다. 그래서 **띠는 0 이 아니라 최소가 목표다.**
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
## 정수 나눗셈이 곧 내림이다. 화면이 논리보다 작아도 1 밑으로는 안 내려간다 —
## 0 배는 아무것도 안 그리는 것이고, 그건 띠가 아니라 고장이다.
static func max_scale(avail: Vector2i, logical_size: Vector2i) -> int:
	if logical_size.x <= 0 or logical_size.y <= 0:
		return 1
	if avail.x <= 0 or avail.y <= 0:
		return 1
	return maxi(1, mini(avail.x / logical_size.x, avail.y / logical_size.y))

## 그 배율로 실제로 그려지는 크기(px).
static func drawn(avail: Vector2i, logical_size: Vector2i) -> Vector2i:
	return logical_size * max_scale(avail, logical_size)

## **남는 띠**(px) — 가로·세로 **합**이다. 한쪽에 절반씩 붙는다.
## 이 수가 이 회차가 줄이려던 그것이고, 잰 값은 NUMBERS 1절에 있다.
static func bars(avail: Vector2i, logical_size: Vector2i) -> Vector2i:
	return avail - drawn(avail, logical_size)

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

## 지금 이 기계에서 전체 화면 창이 받게 될 크기.
static func avail() -> Vector2i:
	if not has_screen():
		return Vector2i.ZERO
	return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size

## **전체 화면으로 띄운다.** 배율을 코드가 거는 게 아니다 — `stretch/scale_mode=integer`
## 가 창 크기에서 제가 내림한다. 여기서 구하는 값은 **그 결과를 미리 말해 두는 것**이고,
## 게이트가 「엔진이 실제로 건 배율」과 맞대 본다 (measure_window.gd 의 VIEW).
##
## **`MODE_FULLSCREEN` 이지 `EXCLUSIVE` 가 아니다**: macOS 에서 exclusive 는 제 Space 를
## 만들어 화면이 통째로 넘어간다 — 한 판에 창을 62번 띄우는 대조군이 그 위에서 못 돈다.
## 둘 다 같은 3456×2168 을 줬다 (2026-09-15 실측).
static func go_fullscreen(w: Window) -> void:
	if not has_screen() or w == null:
		return
	w.mode = Window.MODE_FULLSCREEN

## 사람이 읽는 한 줄. 「그려진 크기 = 논리 × 정수배」와 「남는 띠」를 같이 낸다 —
## 둘 중 하나만 내면 「배율은 맞는데 화면이 안 맞는다」를 아무도 못 본다.
static func report() -> String:
	var lg := logical()
	var av := avail()
	var s := max_scale(av, lg)
	var d := drawn(av, lg)
	var b := bars(av, lg)
	return "DISPLAY 쓸 수 있는 화면 %dx%d · 논리 %dx%d · 배율 %dx · 그린 크기 %dx%d · 띠 %dx%d (%.1f%% x %.1f%%) · 묶는 축 %s" % [
		av.x, av.y, lg.x, lg.y, s, d.x, d.y, b.x, b.y,
		100.0 * b.x / maxf(av.x, 1.0), 100.0 * b.y / maxf(av.y, 1.0),
		binding_axis(av, lg)]
