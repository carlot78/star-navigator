class_name TestHelpers
extends RefCounted
## Builders for model objects so tests do not touch DataRegistry or .tres files.


static func hull(overrides: Dictionary = {}) -> HullData:
	var h := HullData.new()
	h.id = "test_hull"
	h.hull_points = 1000.0
	h.armor = 100.0
	h.max_flux = 1000.0
	h.flux_dissipation = 100.0
	h.shield_arc = 180.0
	h.shield_efficiency = 1.0
	h.max_speed = 100.0
	h.acceleration = 100.0
	h.turn_rate = 90.0
	var slot := WeaponSlotData.new()
	slot.id = "gun"
	slot.position = Vector2(10, 0)
	slot.arc = 90.0
	slot.mount = WeaponSlotData.Mount.UNIVERSAL
	h.weapon_slots = [slot]
	for key: String in overrides:
		h.set(key, overrides[key])
	return h


static func weapon(overrides: Dictionary = {}) -> WeaponData:
	var w := WeaponData.new()
	w.id = "test_gun"
	w.damage = 100.0
	w.damage_type = WeaponData.DamageType.ENERGY
	w.range = 600.0
	w.projectile_speed = 600.0
	w.refire_delay = 0.5
	w.flux_per_shot = 50.0
	for key: String in overrides:
		w.set(key, overrides[key])
	return w


## Two ships 300 px apart on the X axis, facing each other, each with one gun.
static func duel(weapon_overrides: Dictionary = {}) -> CombatSim:
	var sim := CombatSim.new()
	sim.add_ship(hull(), {"gun": weapon(weapon_overrides)}, 0, Vector2(-150, 0), 0.0)
	sim.add_ship(hull(), {"gun": weapon(weapon_overrides)}, 1, Vector2(150, 0), PI)
	return sim
