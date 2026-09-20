class_name ShipAI
extends RefCounted
## Pilot AI v1 (FR-CBT-4): picks the nearest enemy, holds a preferred range,
## raises the shield when shots are inbound, vents when it is safe to, and
## backs out of the arena when the hull runs low.

const RETREAT_HULL_FRACTION := 0.25
const SHIELD_DOWN_FLUX_FRACTION := 0.85
const VENT_FLUX_FRACTION := 0.65
const THREAT_DISTANCE := 450.0
## Fraction of the longest weapon range the AI tries to sit at.
const PREFERRED_RANGE_FRACTION := 0.7


static func decide(ship: ShipState, sim: CombatSim) -> ShipCommand:
	var cmd := ShipCommand.new()
	var target := sim.nearest_enemy(ship)
	if target == null:
		return cmd
	var to_target := target.position - ship.position
	var distance := to_target.length()
	var direction := to_target / maxf(distance, 0.001)
	var max_range := ship.max_weapon_range()
	var preferred := max_range * PREFERRED_RANGE_FRACTION
	cmd.face = direction
	cmd.aim = lead_point(ship, target)
	if ship.hull_fraction() < RETREAT_HULL_FRACTION:
		ship.retreating = true
	if ship.retreating:
		cmd.move = -direction
		cmd.shield = true
		return cmd
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
