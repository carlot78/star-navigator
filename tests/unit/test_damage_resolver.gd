extends TestCase
## DamageResolver: shields, armour, hull and the damage-type table (FR-CBT-2/3).


func _ship(shield_up: bool) -> ShipState:
	var ship := ShipState.new(1, 0, TestHelpers.hull(), Vector2.ZERO, 0.0)
	ship.shield_up = shield_up
	return ship


func test_modifier_table() -> void:
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.KINETIC, "shield"), 2.0)
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.KINETIC, "armor"), 0.5)
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.HIGH_EXPLOSIVE, "armor"), 2.0)
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.HIGH_EXPLOSIVE, "shield"), 0.5)
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.ENERGY, "hull"), 1.0)
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.FRAGMENTATION, "shield"), 0.25)
	assert_eq(DamageResolver.modifier(WeaponData.DamageType.FRAGMENTATION, "hull"), 1.0)


func test_shield_absorbs_frontal_hit_as_flux() -> void:
	var ship := _ship(true)
	var hit := DamageResolver.apply_hit(ship, 100.0, WeaponData.DamageType.KINETIC, 0.0)
	assert_true(hit.shield, "frontal hit is on the shield")
	assert_almost(ship.flux, 200.0, 0.001, "kinetic doubles against shields")
	assert_almost(ship.hull_points, 1000.0, 0.001, "hull untouched")
	assert_false(hit.overloaded)


func test_shield_does_not_cover_the_rear() -> void:
	var ship := _ship(true)
	var hit := DamageResolver.apply_hit(ship, 100.0, WeaponData.DamageType.ENERGY, PI)
	assert_false(hit.shield, "a 180-degree shield leaves the back open")
	assert_eq(ship.flux, 0.0)
	assert_lt(ship.hull_points, 1000.0)


func test_shield_efficiency_scales_flux() -> void:
	var ship := ShipState.new(1, 0, TestHelpers.hull({"shield_efficiency": 0.5}), Vector2.ZERO, 0.0)
	ship.shield_up = true
	DamageResolver.apply_hit(ship, 100.0, WeaponData.DamageType.ENERGY, 0.0)
	assert_almost(ship.flux, 50.0)


func test_overload_when_flux_fills() -> void:
	var ship := _ship(true)
	ship.flux = 950.0
	var hit := DamageResolver.apply_hit(ship, 100.0, WeaponData.DamageType.ENERGY, 0.0)
	assert_true(hit.overloaded)
	assert_true(ship.is_overloaded())
	assert_false(ship.shield_up, "overload drops the shield")
	assert_eq(ship.flux, 1000.0, "flux is capped at max")


func test_armor_reduces_and_depletes() -> void:
	var ship := _ship(false)
	var hit := DamageResolver.apply_hit(ship, 100.0, WeaponData.DamageType.ENERGY, 0.0)
	# vs_armor = 100 against armour 100 gives factor 0.5
	assert_almost(hit.hull, 50.0, 0.001, "half the damage reaches the hull")
	assert_almost(ship.armor[ShipState.Quadrant.FRONT], 50.0, 0.001, "armour lost half of 100")
	assert_almost(ship.armor[ShipState.Quadrant.BACK], 100.0, 0.001, "other sides untouched")
	assert_almost(ship.hull_points, 950.0)


func test_armor_floor_lets_small_hits_through() -> void:
	var ship := ShipState.new(1, 0, TestHelpers.hull({"armor": 1000.0}), Vector2.ZERO, 0.0)
	var hit := DamageResolver.apply_hit(ship, 20.0, WeaponData.DamageType.KINETIC, 0.0)
	assert_almost(hit.hull, 20.0 * DamageResolver.MIN_ARMOR_FACTOR, 0.001, "never below the 15% floor")


func test_high_explosive_strips_armor_faster_than_kinetic() -> void:
	var he := _ship(false)
	var kin := _ship(false)
	DamageResolver.apply_hit(he, 100.0, WeaponData.DamageType.HIGH_EXPLOSIVE, 0.0)
	DamageResolver.apply_hit(kin, 100.0, WeaponData.DamageType.KINETIC, 0.0)
	assert_lt(he.armor[0], kin.armor[0])
	assert_lt(he.hull_points, kin.hull_points)


func test_bare_hull_takes_full_damage_and_dies() -> void:
	var ship := _ship(false)
	ship.armor = [0.0, 0.0, 0.0, 0.0]
	ship.hull_points = 80.0
	var hit := DamageResolver.apply_hit(ship, 100.0, WeaponData.DamageType.FRAGMENTATION, 0.0)
	assert_almost(hit.hull, 100.0, 0.001, "fragmentation is full damage on bare hull")
	assert_true(hit.killed)
	assert_false(ship.alive)
	assert_eq(ship.hull_points, 0.0)


func test_quadrants_follow_heading() -> void:
	var ship := ShipState.new(1, 0, TestHelpers.hull(), Vector2.ZERO, PI * 0.5)
	assert_eq(ship.quadrant_for(PI * 0.5), ShipState.Quadrant.FRONT)
	assert_eq(ship.quadrant_for(-PI * 0.5), ShipState.Quadrant.BACK)
	assert_eq(ship.quadrant_for(PI), ShipState.Quadrant.RIGHT)
	assert_eq(ship.quadrant_for(0.0), ShipState.Quadrant.LEFT)
