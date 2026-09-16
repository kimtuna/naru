class_name UiTheme
extends RefCounted
## 게임 UI 테마 — 글자 크기는 테마 파일 한 곳에만 둔다 (spec/01_settings/display.md).
## 기준 화면 640×360 에 그린 뒤 늘리므로, 글자 크기는 기준 화면 픽셀이다 (1280×720 창이면 두 배로 보인다).
## 장면 · 코드에서 글자 크기를 따로 정하지 않는다 — 작은 글자가 필요하면 테마에 타입 변형을 더한다.

## 프로젝트 설정 gui/theme/custom 이 가리키는 테마.
const PATH := "res://ui/theme/theme.tres"
## 칸 안의 숫자(숫자키 · 개수) 같은 작은 글자용 타입 변형 — 테마에 정의돼 있다.
const SMALL_LABEL := &"SmallLabel"
## 640×360 에서 읽을 수 있는 가장 작은 글자 — 이보다 작으면 한글 획이 뭉개진다. 임시 값.
const MIN_FONT_SIZE := 10
## 이보다 크면 기준 화면에 줄이 몇 개 안 들어간다. 임시 값.
const MAX_FONT_SIZE := 16
