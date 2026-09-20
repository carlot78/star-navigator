class_name ShipState
extends RefCounted
## One ship inside a battle: its static hull data plus everything that
## changes while fighting (position, flux, armour per side, hull points).
## Pure model, no nodes; CombatSim steps it and ShipView draws it.

enum Quadrant { FRONT, RIGHT, BACK, LEFT }

const RADIUS_BY_SIZE := {
	HullData.Size.FRIGATE: 22.0,
	HullData.Size.DESTROYER: 34.0,
	HullData.Size.CRUISER: 50.0,
	HullData.Size.CAPITAL: 70.0,
}
const OVERLOAD_SECONDS := 4.0

var id: int
## 0 = player side, 1 = enemy side.
var side: int
var hull: HullData
var mounts: Array[WeaponMount] = []
var command := ShipCommand.new()

var position: Vector2
var velocity: Vector2 = Vector2.ZERO
## Radians, 0 = +X.
var heading: float
## Collision radius, from the hull size.
var radius: float

var hull_points: float
## Armour left on each side, indexed by Quadrant.
var armor: Array[float] = []
var flux: float = 0.0
var overload_left: float = 0.0
var shield_up: bool = false
var venting: bool = false
var retreating: bool = false
var alive: bool = true
## Left the arena by retreating: out of the fight but not destroyed.
var escaped: bool = false


func _init(p_id: int, p_side: int, p_hull: HullData, p_position: Vector2, p_heading: float) -> void:
	id = p_id
	side = p_side
	hull = p_hull
	position = p_position
	heading = p_heading
	radius = RADIUS_BY_SIZE.get(p_hull.size, 22.0)
	hull_points = p_hull.hull_points
	armor = [p_hull.armor, p_hull.armor, p_hull.armor, p_hull.armor]


func hull_fraction() -> float:
	return clampf(hull_points / hull.hull_points, 0.0, 1.0)


func flux_fraction() -> float:
	return clampf(flux / hull.max_flux, 0.0, 1.0)


func is_overloaded() -> bool:
	return overload_left > 0.0


## Alive, in the arena and not overloaded: able to fire and raise shields.
func can_act() -> bool:
	return alive and not escaped and not is_overloaded()


## In the fight: alive and still inside the arena.
func in_battle() -> bool:
	return alive and not escaped


## Which side of the ship faces a world-space direction (from the ship outward).
func quadrant_for(world_angle: float) -> Quadrant:
	var rel := wrapf(world_angle - heading, -PI, PI)
	if absf(rel) <= PI * 0.25:
		return Quadrant.FRONT
	if absf(rel) >= PI * 0.75:
		return Quadrant.BACK
	return Quadrant.RIGHT if rel > 0.0 else Quadrant.LEFT


## True when the raised shield covers a world-space direction (from the ship outward).
func shield_covers(world_angle: float) -> bool:
	if not shield_up:
		return false
	return absf(wrapf(world_angle - heading, -PI, PI)) <= deg_to_rad(hull.shield_arc) * 0.5


func max_weapon_range() -> float:
	var best := 0.0
	for mount in mounts:
		best = maxf(best, mount.weapon.range)
	return best


func to_dict() -> Dictionary:
	return {
		"id": id,
		"side": side,
		"hull": hull.id,
		"hull_fraction": hull_fraction(),
		"alive": alive,
		"escaped": escaped,
	}
