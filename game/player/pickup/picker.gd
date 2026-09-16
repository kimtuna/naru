class_name Picker
extends Node
## 밟으면 줍기 — 플레이어가 떨어진 아이템 위를 지나가면 클릭 없이 가방에 넣는다 (spec/02_player/pickup.md).
## 가방에 못 넣은 몫은 바닥에 그대로 남는다. 가방에 자리가 나면 다음 걸음에 마저 줍는다.

## 하나를 (일부라도) 주웠을 때. left 는 바닥에 남은 개수.
signal picked(item_id: String, amount: int, left: int)

var player: Player
## 떨어진 아이템들의 부모.
var drops: Node2D
## 칸 크기 (픽셀) — 줍기 거리를 타일 수에서 바꾼다.
var tile_px := 16


func setup(who: Player, drops_parent: Node2D, tile_size: int) -> void:
	player = who
	drops = drops_parent
	tile_px = tile_size


func radius_px() -> float:
	return PickupConfig.RADIUS_TILES * tile_px


func _physics_process(_delta: float) -> void:
	pick_up()


## 발밑의 떨어진 아이템을 줍는다. 주운 아이템 수.
func pick_up() -> int:
	if player == null or drops == null:
		return 0
	var n := 0
	for child in drops.get_children():
		var drop := child as DroppedItem
		if drop == null or drop.is_queued_for_deletion():
			continue
		if drop.global_position.distance_to(player.global_position) > radius_px():
			continue
		var before := drop.count()
		var left := player.hotbar.inventory.add(drop.item)
		if left == before:
			continue
		n += 1
		if left <= 0:
			drops.remove_child(drop)
			drop.queue_free()
		else:
			drop.set_count(left)
		picked.emit(drop.item_id(), before - left, left)
	return n
