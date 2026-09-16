class_name GrappleConfig
extends Resource
## 갈고리총 수치 — 등급(아이템 id)마다 최대 거리 · 탄창 · 발사 간격, 날아가는 속력 (값은 life/climbing/grapple_config.tres).
## spec/04_life/climbing.md: 등급별 최대 거리는 미정 — 임시 값이다. 사람이 플레이해 보고 바꾼다.

const DEFAULT_PATH := "res://life/climbing/grapple_config.tres"
## 핫바 칸 아이템에 남은 탄 수를 적는 키. 없으면 탄창이 가득 찬 것이다 (갓 만든 갈고리총).
const LOADED_KEY := "loaded"

## 갈고리총 아이템 id → {"range_tiles": 최대 거리(칸), "magazine": 탄창 크기(발), "interval": 발사 간격(초)}.
@export var guns := {
	"grapple_gun": {"range_tiles": 4.0, "magazine": 2, "interval": 0.3},
	"grapple_gun_2": {"range_tiles": 8.0, "magazine": 4, "interval": 0.3},
}
## 걸린 곳으로 날아가는 속력 (초당 픽셀).
@export var fly_speed := 320.0
## 날아갈 길을 이만큼(픽셀)씩 짚어 막힌 칸(바다 · 자원 · 섬 밖) 앞에서 멈춘다.
@export var path_step_px := 2.0


static func load_default() -> GrappleConfig:
	return load(DEFAULT_PATH) as GrappleConfig


## 이 아이템(핫바 칸 값, 빈손이면 null)이 갈고리총인가.
func is_grapple(item: Variant) -> bool:
	return item is Dictionary and guns.has(str(item.get("id", "")))


## 갈고리총의 수치 하나. 갈고리총이 아니면 0.
func stat(item: Variant, key: String) -> float:
	if not is_grapple(item):
		return 0.0
	return float(guns[str(item.get("id", ""))].get(key, 0.0))


func max_range_px(item: Variant, tile_px: int) -> float:
	return stat(item, "range_tiles") * tile_px


func magazine(item: Variant) -> int:
	return int(stat(item, "magazine"))


## 탄창에 남은 탄 수.
func loaded(item: Variant) -> int:
	if not is_grapple(item):
		return 0
	return clampi(int(item.get(LOADED_KEY, magazine(item))), 0, magazine(item))


## from 에서 pointer 쪽으로 쏘면 걸리는 곳 — 최대 거리보다 멀면 최대 거리 지점, 짧으면 겨눈 지점.
static func hook_point(from: Vector2, pointer: Vector2, max_px: float) -> Vector2:
	var to := pointer - from
	if to.length() <= max_px:
		return pointer
	return from + to.normalized() * max_px
