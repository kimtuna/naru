extends "res://tests/life/harvest/harvest_test_base.gd"
## G-009 3단계 데스 상자 테스트가 함께 쓰는 준비. 파일 이름이 test_ 로 시작하지 않아 혼자서는 돌지 않는다.

const WOOD := {"id": "wood", "count": 7}
const STONE := {"id": "stone", "count": 3}


func _chest_seconds() -> float:
	return DamageConfig.load_default().death_chest_seconds


## 핫바에 도끼, 가방 뒤쪽 칸(핫바 밖)에 돌, 그리고 나무를 넣는다.
func _fill_bag(game: GameScene) -> Inventory:
	var inv := game.player().hotbar.inventory
	_hold(game, AXE)
	assert_true(inv.set_slot(InventoryConfig.BAG_SIZE - 1, STONE.duplicate()))
	assert_eq(inv.add(WOOD.duplicate()), 0)
	return inv


func _bag_is_empty(inv: Inventory) -> bool:
	for i in inv.size():
		if inv.slot(i) != null:
			return false
	return true


## 스폰에서 떨어진 자리에서 죽인다. 죽은 자리를 돌려준다.
func _die_at(game: GameScene, offset: Vector2) -> Vector2:
	var p := game.player()
	var at := p.spawn_point + offset
	p.global_position = at
	assert_true(p.take_damage(p.health.max_health * 2.0), "dies")
	return at


func _set_penalty(game: GameScene, on: bool) -> void:
	assert_true(game.world.settings.set_death_penalty(on, true))


## 상자 옆에 선다 (손이 닿게).
func _stand_by(game: GameScene, chest: DeathChest) -> void:
	game.player().global_position = chest.position + Vector2(4, 0)
