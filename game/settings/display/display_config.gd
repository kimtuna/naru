class_name DisplayConfig
extends RefCounted
## 화면 배율 수치 한 곳 (spec/01_settings/display.md).
## 기준 화면 640×360 을 창에 맞춰 늘린다 — 보이는 월드 범위는 창 크기와 상관없이 같다 (PvP).
## 실제 적용은 project.godot 의 [display] 가 한다. 이 파일과 값이 같아야 한다 (테스트가 본다).

## 기준 화면 (게임 픽셀). UI 는 이 크기로 배치한다. 월드는 CAMERA_ZOOM 배로 확대해 보인다.
const BASE_SIZE := Vector2i(640, 360)
## 처음 뜨는 창 크기 — 기준 화면의 정수 배.
const WINDOW_SIZE := Vector2i(1280, 720)
## 늘리는 방식 — 기준 화면째로 그린 뒤 늘린다 (도트가 깨끗하다). UI · 글자도 같이 커진다.
const STRETCH_MODE := "viewport"
## 16:9 가 아니면 비율을 지키고 남는 곳은 검은 띠.
const STRETCH_ASPECT := "keep"
## 정수 배율을 먼저 쓴다 — 창이 기준 화면보다 작을 때만 엔진이 소수 배율로 줄인다.
const STRETCH_SCALE_MODE := "integer"
## 월드 카메라 배율 — 고정이다. 보이는 범위를 바꾸는 플레이어 설정을 두지 않는다.
## 시험 중 (2026-09-18): 2배 → 보이는 월드 20×11.25칸. UI(HUD · 창)는 카메라를 안 따라 640×360 그대로.
const CAMERA_ZOOM := Vector2(2.0, 2.0)


## 카메라 확대를 고정 값으로 맞춘다.
static func lock_camera(cam: Camera2D) -> void:
	cam.zoom = CAMERA_ZOOM
