class_name Gunner
extends Node
## 총 쏘기 — 총을 들고 좌클릭하면 휘두르지 않고 Pointer(마우스) 방향으로 투사체를 쏜다.
## 한 발에 탄약을 가방에서 뺀다. 탄약이 모자라면 쏘지 않는다 (휘두르지도 않는다).
## Swinger.alternate 에 try_fire 를 걸어 좌클릭 · 쥐고 있기 · 막힘 처리를 그대로 쓴다.

signal fired(projectile: Projectile)
## 탄약이 없어 못 쐈다.
signal dry_fired

## 비워 두면 gun_config.tres 를 쓴다.
@export var config: GunConfig

var player: Player
## 몹들의 부모 — 투사체가 맞을 대상.
var mobs: Node
## 투사체들의 부모.
var projectiles: Node


func _ready() -> void:
	if config == null:
		config = GunConfig.load_default()


func setup(who: Player, mobs_parent: Node, projectiles_parent: Node) -> void:
	player = who
	mobs = mobs_parent
	projectiles = projectiles_parent


## 손에 든 것이 총이면 쏘고(탄약이 있으면) 다음 발까지 기다릴 초를, 총이 아니면 -1 을 돌려준다.
func try_fire(item: Variant) -> float:
	if not config.is_gun(item):
		return -1.0
	fire(item)
	return config.stat(item, "interval")


## 한 발 쏜다. 쏜 투사체 (탄약이 없으면 null).
func fire(gun: Variant) -> Projectile:
	if player == null or projectiles == null or not config.is_gun(gun):
		return null
	if not player.hotbar.inventory.remove(config.ammo_id, config.ammo_per_shot):
		dry_fired.emit()
		return null
	player.update_facing()
	var dir := player.facing
	var p := Projectile.create(dir, gun, config, mobs)
	projectiles.add_child(p)
	p.global_position = player.global_position + dir * config.muzzle_offset
	fired.emit(p)
	return p
