class_name CombatSim
extends RefCounted
## The battle as a pure, fixed-timestep simulation: ships obey their
## ShipCommand, weapons spawn projectiles, projectiles hit hulls through
## DamageResolver. No nodes; combat.tscn steps it from _physics_process and
## draws the state. Same commands in, same battle out (NFR-6).

## Shields cost dissipation while raised; venting multiplies it.
const SHIELD_DISSIPATION_FACTOR := 0.5
const VENT_DISSIPATION_FACTOR := 3.0

var arena: Rect2 = Rect2(-1200.0, -800.0, 2400.0, 1600.0)
var time: float = 0.0
var ships: Array[ShipState] = []
var projectiles: Array[ProjectileState] = []
## Hits landed during the last step, for effects: DamageResolver results plus
## "position" and "ship_id".
var hits: Array[Dictionary] = []
## Notable events of the last step: {"type": "killed"|"escaped"|"overloaded", "ship_id": id}.
var events: Array[Dictionary] = []

var _next_id: int = 1


## Adds a ship. `fit` maps slot id → WeaponData; slots without an entry stay empty.
func add_ship(hull: HullData, fit: Dictionary, side: int, position: Vector2, heading: float) -> ShipState:
	var ship := ShipState.new(_next_id, side, hull, position, heading)
	_next_id += 1
	for slot in hull.weapon_slots:
		var weapon: WeaponData = fit.get(slot.id)
		if weapon != null:
			ship.mounts.append(WeaponMount.new(slot, weapon))
	ships.append(ship)
	return ship


func ship_by_id(id: int) -> ShipState:
	for ship in ships:
		if ship.id == id:
			return ship
	return null


func ships_in_battle(side: int) -> Array[ShipState]:
	var out: Array[ShipState] = []
	for ship in ships:
		if ship.side == side and ship.in_battle():
			out.append(ship)
	return out


func nearest_enemy(ship: ShipState) -> ShipState:
	var best: ShipState = null
	var best_distance := INF
	for other in ships:
		if other.side == ship.side or not other.in_battle():
			continue
		var d := other.position.distance_squared_to(ship.position)
		if d < best_distance:
			best_distance = d
			best = other
	return best


## {} while the battle is undecided; otherwise {"winner": side or -1, "time": seconds}.
func outcome() -> Dictionary:
	var player_left := ships_in_battle(0).size()
	var enemy_left := ships_in_battle(1).size()
	if player_left > 0 and enemy_left > 0:
		return {}
	var winner := -1
	if player_left > 0:
		winner = 0
	elif enemy_left > 0:
		winner = 1
	return {"winner": winner, "time": time}


func step(delta: float) -> void:
	hits.clear()
	events.clear()
	time += delta
	for ship in ships:
		if ship.in_battle():
			_step_ship(ship, delta)
	_step_projectiles(delta)


func _step_ship(ship: ShipState, delta: float) -> void:
	var cmd := ship.command
	# Overload, venting and shields.
	if ship.is_overloaded():
		ship.overload_left = maxf(0.0, ship.overload_left - delta)
		ship.shield_up = false
		ship.venting = false
	else:
		ship.venting = cmd.vent and ship.flux > 0.0
		ship.shield_up = cmd.shield and not ship.venting
	var dissipation := ship.hull.flux_dissipation
	if ship.venting:
		dissipation *= VENT_DISSIPATION_FACTOR
	elif ship.shield_up:
		dissipation *= SHIELD_DISSIPATION_FACTOR
	ship.flux = maxf(0.0, ship.flux - dissipation * delta)
	# Movement: omnidirectional thrust toward the commanded direction.
	var move := cmd.move.limit_length(1.0)
	ship.velocity = ship.velocity.move_toward(move * ship.hull.max_speed, ship.hull.acceleration * delta)
	ship.position += ship.velocity * delta
	var inset := arena.grow(-ship.radius)
	var clamped := Vector2(clampf(ship.position.x, inset.position.x, inset.end.x),
		clampf(ship.position.y, inset.position.y, inset.end.y))
	if ship.retreating and clamped != ship.position:
		ship.escaped = true
		events.append({"type": "escaped", "ship_id": ship.id})
		return
	ship.position = clamped
	var face := cmd.face if cmd.face != Vector2.ZERO else move
	if face.length_squared() > 0.0:
		ship.heading = rotate_toward(ship.heading, face.angle(), deg_to_rad(ship.hull.turn_rate) * delta)
	# Weapons.
	for mount in ship.mounts:
		mount.cooldown = maxf(0.0, mount.cooldown - delta)
		if not cmd.fire or not ship.can_act() or ship.venting or mount.cooldown > 0.0:
			continue
		if not mount.has_ammo() or not mount.can_aim_at(ship, cmd.aim):
			continue
		if ship.flux + mount.weapon.flux_per_shot > ship.hull.max_flux:
			continue
		_fire(ship, mount, cmd.aim)


func _fire(ship: ShipState, mount: WeaponMount, aim: Vector2) -> void:
	var weapon := mount.weapon
	var origin := mount.world_position(ship)
	var shot := ProjectileState.new()
	shot.position = origin
	shot.velocity = (aim - origin).normalized() * weapon.projectile_speed
	shot.damage = weapon.damage
	shot.damage_type = weapon.damage_type
	shot.side = ship.side
	shot.owner_id = ship.id
	shot.life = weapon.range / maxf(weapon.projectile_speed, 1.0)
	projectiles.append(shot)
	mount.cooldown = weapon.refire_delay
	mount.consume_ammo()
	ship.flux += weapon.flux_per_shot


func _step_projectiles(delta: float) -> void:
	for shot in projectiles:
		shot.position += shot.velocity * delta
		shot.life -= delta
		if shot.life <= 0.0 or not arena.has_point(shot.position):
			shot.alive = false
			continue
		for ship in ships:
			if ship.side == shot.side or not ship.in_battle():
				continue
			var reach := ship.radius + shot.radius
			if ship.position.distance_squared_to(shot.position) > reach * reach:
				continue
			var source_angle := (shot.position - ship.position).angle()
			var hit := DamageResolver.apply_hit(ship, shot.damage, shot.damage_type, source_angle)
			hit["position"] = shot.position
			hit["ship_id"] = ship.id
			hits.append(hit)
			if hit.killed:
				events.append({"type": "killed", "ship_id": ship.id})
			elif hit.overloaded:
				events.append({"type": "overloaded", "ship_id": ship.id})
			shot.alive = false
			break
	projectiles = projectiles.filter(func(s: ProjectileState) -> bool: return s.alive)
