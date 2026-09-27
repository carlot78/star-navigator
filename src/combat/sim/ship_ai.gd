class_name ShipAI
extends RefCounted
## Pilot AI (FR-CBT-4, FR-CBT-5): follows the ship's fleet order, holds a
## preferred range against its target, raises the shield when threatened,
## vents when it is safe to, and heads for its own arena edge when ordered
## to retreat or when the hull runs low.

const RETREAT_HULL_FRACTION := 0.25
const SHIELD_DOWN_FLUX_FRACTION := 0.85
const VENT_FLUX_FRACTION := 0.65
const THREAT_DISTANCE := 450.0
## Fraction of the longest weapon range the AI tries to sit at.
const PREFERRED_RANGE_FRACTION := 0.7
## DEFEND: enemies closer than this to the point (plus weapon range) are engaged.
const DEFEND_RADIUS := 300.0
## DEFEND: how far from the point counts as "on station".
const STATION_RADIUS := 80.0


static func decide(ship: ShipState, sim: CombatSim) -> ShipCommand:
	var cmd := ShipCommand.new()
	if ship.hull_fraction() < RETREAT_HULL_FRACTION:
		ship.retreating = true
	var nearest := sim.nearest_enemy(ship)
	if ship.retreating:
		return _retreat(ship, nearest)
	var target := choose_target(ship, sim)
	if target == null:
		# Nothing to fight here: DEFEND goes back to its point, others face the nearest threat.
		if ship.order == ShipState.Order.DEFEND:
			cmd.move = _toward(ship.position, ship.order_point, STATION_RADIUS)
		if nearest != null:
			cmd.face = (nearest.position - ship.position).normalized()
			cmd.shield = is_threatened(ship, sim, nearest)
		return cmd
	var to_target := target.position - ship.position
	var distance := to_target.length()
	var direction := to_target / maxf(distance, 0.001)
	var max_range := ship.max_weapon_range()
	var preferred := max_range * PREFERRED_RANGE_FRACTION
	cmd.face = direction
	cmd.aim = lead_point(ship, target)
	var threatened := is_threatened(ship, sim, target)
	if distance > preferred:
		cmd.move = direction
	elif distance < preferred * 0.5:
		cmd.move = -direction
	else:
		cmd.move = direction.orthogonal() * 0.6
	var flux := ship.flux_fraction()
	if flux > VENT_FLUX_FRACTION and not threatened and distance > preferred * 0.9:
		cmd.vent = true
		cmd.move = -direction
	cmd.shield = threatened and flux < SHIELD_DOWN_FLUX_FRACTION
	cmd.fire = distance <= max_range and not cmd.vent
	return cmd


## The enemy this ship should fight under its order, or null.
static func choose_target(ship: ShipState, sim: CombatSim) -> ShipState:
	match ship.order:
		ShipState.Order.ENGAGE:
			if ship.order_target_id >= 0:
				var ordered := sim.ship_by_id(ship.order_target_id)
				if ordered != null and ordered.in_battle():
					return ordered
			return sim.nearest_enemy(ship)
		ShipState.Order.DEFEND:
			var reach := DEFEND_RADIUS + ship.max_weapon_range()
			var best: ShipState = null
			var best_distance := reach * reach
			for other in sim.ships:
				if other.side == ship.side or not other.in_battle():
					continue
				var d := other.position.distance_squared_to(ship.order_point)
				if d <= best_distance:
					best_distance = d
					best = other
			return best
	return null


## Where to aim so the first weapon's shot meets the target if it keeps its velocity.
static func lead_point(ship: ShipState, target: ShipState) -> Vector2:
	if ship.mounts.is_empty():
		return target.position
	var speed := ship.mounts[0].weapon.projectile_speed
	var flight := ship.position.distance_to(target.position) / maxf(speed, 1.0)
	return target.position + target.velocity * flight


## Enemy shots closing in, or an enemy able to reach us with its guns.
static func is_threatened(ship: ShipState, sim: CombatSim, target: ShipState) -> bool:
	if ship.position.distance_to(target.position) <= target.max_weapon_range() * 1.1:
		return true
	for shot in sim.projectiles:
		if shot.side == ship.side:
			continue
		var to_ship := ship.position - shot.position
		if to_ship.length() <= THREAT_DISTANCE and shot.velocity.dot(to_ship) > 0.0:
			return true
	return false


## Head for the own arena edge, shield toward the nearest enemy, shoot back if it is close.
static func _retreat(ship: ShipState, nearest: ShipState) -> ShipCommand:
	var cmd := ShipCommand.new()
	cmd.move = CombatSim.retreat_direction(ship.side)
	cmd.shield = true
	if nearest != null:
		var to_enemy := nearest.position - ship.position
		cmd.face = to_enemy.normalized()
		cmd.aim = lead_point(ship, nearest)
		cmd.fire = to_enemy.length() <= ship.max_weapon_range() and ship.flux_fraction() < 0.5
		if ship.flux_fraction() >= SHIELD_DOWN_FLUX_FRACTION:
			cmd.shield = false
	return cmd


static func _toward(from: Vector2, to: Vector2, slack: float) -> Vector2:
	var offset := to - from
	if offset.length() <= slack:
		return Vector2.ZERO
	return offset.normalized()
