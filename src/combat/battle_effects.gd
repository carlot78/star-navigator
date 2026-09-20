extends Node2D
## Draws everything in the battle that is not a ship: the arena boundary,
## projectiles (from the sim, every frame) and short-lived hit flashes.

const ARENA_COLOR := Color(0.5, 0.6, 1.0, 0.25)
const SHOT_COLORS := {
	WeaponData.DamageType.KINETIC: Color(1.0, 0.9, 0.5),
	WeaponData.DamageType.HIGH_EXPLOSIVE: Color(1.0, 0.55, 0.3),
	WeaponData.DamageType.ENERGY: Color(0.55, 0.9, 1.0),
	WeaponData.DamageType.FRAGMENTATION: Color(0.95, 0.95, 0.95),
}
const SHIELD_FLASH := Color(0.5, 0.8, 1.0)
const HULL_FLASH := Color(1.0, 0.6, 0.3)
const FLASH_SECONDS := 0.35

var sim: CombatSim
var _flashes: Array[Dictionary] = []


func _process(delta: float) -> void:
	for flash in _flashes:
		flash.age += delta
	_flashes = _flashes.filter(func(f: Dictionary) -> bool: return f.age < FLASH_SECONDS)
	queue_redraw()


func add_hits(hits: Array[Dictionary]) -> void:
	for hit in hits:
		_flashes.append({"position": hit.position, "shield": hit.shield, "age": 0.0,
			"size": 6.0 + minf(14.0, float(hit.hull + hit.flux) * 0.05)})


func _draw() -> void:
	if sim == null:
		return
	draw_rect(sim.arena, ARENA_COLOR, false, 2.0)
	for shot in sim.projectiles:
		var tail := shot.position - shot.velocity.normalized() * 10.0
		draw_line(tail, shot.position, SHOT_COLORS[shot.damage_type], 2.5)
	for flash in _flashes:
		var t: float = flash.age / FLASH_SECONDS
		var color: Color = SHIELD_FLASH if flash.shield else HULL_FLASH
		color.a = 1.0 - t
		draw_arc(flash.position, flash.size * (0.5 + t), 0.0, TAU, 16, color, 2.0, true)
