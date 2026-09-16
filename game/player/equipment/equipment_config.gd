class_name EquipmentConfig
## 장비 칸과 칸에 끼우는 아이템을 한 곳에 모은다 (spec/02_player/equipment.md, spec/04_life/climbing.md).
## 부위를 늘리려면 SLOTS 에 칸을, ITEM_SLOTS 에 그 칸에 끼우는 아이템을 더한다.

const FEET := "feet"
const SPIKES := "spikes"

## 캐릭터의 장비 칸 — 지금은 신발 하나. 칸 이름은 저장 키이기도 하다.
const SLOTS: Array[String] = [FEET]

## 아이템 id → 끼우는 칸.
const ITEM_SLOTS := {
	SPIKES: FEET,
}
