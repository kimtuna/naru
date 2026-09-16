extends "res://tests/craft/stations/station_test_base.gd"
## G-007 2단계 작물 테스트가 함께 쓰는 준비 — 씨앗 · 물뿌리개를 들고 밭을 만들고 날을 넘긴다.
## 파일 이름이 test_ 로 시작하지 않아 혼자서는 돌지 않는다.

const SHOVEL := {"id": "shovel", "count": 1}


func _farm_cfg() -> FarmConfig:
	return FarmConfig.load_default()


func _seeds(count := 5) -> Dictionary:
	return {"id": _farm_cfg().seed_id, "count": count}


func _can() -> Dictionary:
	return {"id": _farm_cfg().watering_can_id, "count": 1}


## 스폰에 서서 오른쪽 맨땅 칸.
func _bare_next_to_spawn(game: GameScene) -> Vector2i:
	var here := game.island.spawn()
	_stand(game, here)
	var cell := here + Vector2i.RIGHT
	assert_true(game.farm().is_bare(cell), "setup: the cell next to spawn is bare ground")
	return cell


## 게임 시계로 하루를 넘긴다.
func _next_day(game: GameScene) -> void:
	game.clock().advance(game.clock().config.day_seconds)


func _wheat_drops(game: GameScene, cell: Vector2i) -> Array:
	return _drops_at(game, cell).filter(func(d: DroppedItem) -> bool: return d.item_id() == _farm_cfg().crop_id)


## 우클릭으로 개간하고 씨앗을 심은 칸.
func _planted(game: GameScene) -> Vector2i:
	var cell := _bare_next_to_spawn(game)
	assert_true(game.farm().dig(cell), "setup: till")
	_hold(game, _seeds())
	assert_true(game.farm().plant(cell), "setup: plant")
	return cell
