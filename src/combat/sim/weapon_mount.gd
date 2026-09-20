class_name WeaponMount
extends RefCounted
## A weapon fitted to one slot of a ship in battle: the static data plus the
## live cooldown and ammunition.

var slot: WeaponSlotData
var weapon: WeaponData
var cooldown: float = 0.0
## Rounds left; -1 means unlimited.
var ammo: int = -1


func _init(p_slot: WeaponSlotData, p_weapon: WeaponData) -> void:
	slot = p_slot
	weapon = p_weapon
	ammo = p_weapon.ammo if p_weapon.ammo > 0 else -1


func has_ammo() -> bool:
	return ammo != 0


func consume_ammo() -> void:
	if ammo > 0:
		ammo -= 1


func world_position(ship: ShipState) -> Vector2:
	return ship.position + slot.position.rotated(ship.heading)


## True when the point lies inside this mount's firing arc.
func can_aim_at(ship: ShipState, point: Vector2) -> bool:
	var to_point := point - world_position(ship)
	if to_point.length_squared() < 1.0:
		return false
	var centre := ship.heading + deg_to_rad(slot.angle)
	return absf(wrapf(to_point.angle() - centre, -PI, PI)) <= deg_to_rad(slot.arc) * 0.5
