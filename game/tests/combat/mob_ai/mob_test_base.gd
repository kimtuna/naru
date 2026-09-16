extends "res://tests/life/harvest/harvest_test_base.gd"
## G-009 6단계 몹 AI 테스트가 함께 쓰는 준비 — 둘레가 트인 자리에 캐릭터를 세우고 몹을 부른다.
## 파일 이름이 test_ 로 시작하지 않아 혼자서는 돌지 않는다.


func world_seed() -> int:
	return 777


func _ai() -> MobConfig:
	return MobConfig.load_default()


## 스폰 칸 둘레 radius 칸의 자원을 치운다 — 몹이 막힘 없이 곧장 다가올 수 있다. 치운 뒤의 가운데 칸.
func _clear_around(game: GameScene, radius: int) -> Vector2i:
	var s := game.island.spawn()
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			game.island.remove_deposit(s + Vector2i(dx, dy))
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			assert_false(game.island.is_blocked(s + Vector2i(dx, dy)), "cleared around spawn")
	return s


## 몹이 쫓아올 만큼 트인 자리에 캐릭터를 세운 게임.
func _enter_open() -> GameScene:
	var game := _enter()
	var tiles := ceili(_ai().lose_radius / game.island_view().tile_px()) + 2
	_stand(game, _clear_around(game, tiles))
	return game


## 조건이 참이 될 때까지 물리 프레임을 넘긴다 (최대 frames). 참이 되었으면 true.
func _wait_until(cond: Callable, frames: int) -> bool:
	for i in frames:
		if cond.call():
			return true
		await wait_physics_frames(1)
	return cond.call()


## 초를 물리 프레임 수로.
func _frames(seconds: float) -> int:
	return ceili(seconds * Engine.physics_ticks_per_second)
