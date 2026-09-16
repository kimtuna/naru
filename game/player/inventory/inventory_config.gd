class_name InventoryConfig
## 인벤토리 · 핫바 수치를 한 곳에 모은다 (spec/02_player/inventory-hotbar.md).

## 핫바 칸 수 — spec 에서 미정, 임시 값. 숫자키 1~9, 0 에 한 칸씩이라 10.
## InputActions.HOTBAR_ACTION_COUNT 보다 클 수 없다 (고를 키가 없다).
const HOTBAR_SIZE := 10
## 가방 전체 칸 수 (앞 HOTBAR_SIZE 칸이 핫바) — spec 미정, 임시 값.
const BAG_SIZE := 30
## 한 칸에 쌓이는 최대 개수 — spec 미정, 임시 값.
const STACK_MAX := 99
