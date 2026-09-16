class_name SaveConfig
## 저장 수치 · 경로를 한 곳에 모은다 (spec/01_settings/save.md).

## 캐릭터 슬롯 수 — 사람 결정 2026-09-16.
const CHARACTER_SLOTS := 3
## 실제 사용자 저장 위치. 테스트는 SaveStore 에 다른 경로를 넘긴다.
const DEFAULT_ROOT := "user://saves"
const CHARACTER_DIR := "characters"
const WORLD_DIR := "worlds"
const FILE_EXT := ".sav"
## 저장 형식 버전 — 형식이 바뀌면 올리고 불러올 때 옮긴다.
const FORMAT_VERSION := 1
