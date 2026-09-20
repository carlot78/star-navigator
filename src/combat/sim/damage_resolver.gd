class_name DamageResolver
extends RefCounted
## The damage pipeline (FR-CBT-2, FR-CBT-3): a hit is absorbed by the shield
## as flux when the shield covers it, otherwise it is reduced by the armour
## of the side it strikes and the remainder reaches the hull.
##
## Damage-type modifiers per layer. Kinetic is strong on shields and weak on
## armour, high explosive the reverse, energy neutral, fragmentation weak on
## both but full against bare hull.

const MODIFIERS := {
	WeaponData.DamageType.KINETIC: {"shield": 2.0, "armor": 0.5, "hull": 1.0},
	WeaponData.DamageType.HIGH_EXPLOSIVE: {"shield": 0.5, "armor": 2.0, "hull": 1.0},
	WeaponData.DamageType.ENERGY: {"shield": 1.0, "armor": 1.0, "hull": 1.0},
	WeaponData.DamageType.FRAGMENTATION: {"shield": 0.25, "armor": 0.25, "hull": 1.0},
}
## Armour never reduces a hit below this fraction of its damage.
const MIN_ARMOR_FACTOR := 0.15


static func modifier(type: WeaponData.DamageType, layer: String) -> float:
	return float(MODIFIERS[type][layer])


## Applies one hit coming from world direction `source_angle` (ship → impact).
## Returns what happened: {shield, flux, armor, hull, overloaded, killed}.
static func apply_hit(ship: ShipState, damage: float, type: WeaponData.DamageType,
		source_angle: float) -> Dictionary:
	var result := {"shield": false, "flux": 0.0, "armor": 0.0, "hull": 0.0, "overloaded": false, "killed": false}
	if ship.shield_covers(source_angle):
		var flux_gain := damage * modifier(type, "shield") * ship.hull.shield_efficiency
		ship.flux += flux_gain
		result.shield = true
		result.flux = flux_gain
		if ship.flux >= ship.hull.max_flux:
			ship.flux = ship.hull.max_flux
			ship.overload_left = ShipState.OVERLOAD_SECONDS
			ship.shield_up = false
			ship.venting = false
			result.overloaded = true
		return result
	var quadrant := ship.quadrant_for(source_angle)
	var armor_value: float = ship.armor[quadrant]
	var vs_armor := damage * modifier(type, "armor")
	var factor := 1.0
	if armor_value > 0.0:
		factor = clampf(vs_armor / (vs_armor + armor_value), MIN_ARMOR_FACTOR, 1.0)
	var armor_loss := minf(armor_value, vs_armor * factor)
	ship.armor[quadrant] = armor_value - armor_loss
	var hull_loss := damage * modifier(type, "hull") * factor
	ship.hull_points -= hull_loss
	result.armor = armor_loss
	result.hull = hull_loss
	if ship.hull_points <= 0.0:
		ship.hull_points = 0.0
		ship.alive = false
		result.killed = true
	return result
