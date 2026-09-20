extends TestCase
## CombatSim: firing, flight, hits, flux, venting, retreat and the outcome.

const DT := 1.0 / 60.0


func _run(sim: CombatSim, seconds: float) -> void:
	for _i in int(seconds / DT):
		sim.step(DT)


func test_fire_spawns_projectile_and_costs_flux() -> void:
	var sim := TestHelpers.duel()
	var shooter := sim.ships[0]
	shooter.command.fire = true
	shooter.command.aim = sim.ships[1].position
	sim.step(DT)
	assert_eq(sim.projectiles.size(), 1)
	assert_almost(shooter.flux, 50.0, 0.01, "shot flux; dissipation ran before the shot")
	assert_almost(shooter.mounts[0].cooldown, 0.5, 0.001, "cooldown set by the shot")
	sim.step(DT)
	assert_eq(sim.projectiles.size(), 1, "no second shot before the cooldown ends")


func test_shot_outside_arc_is_not_fired() -> void:
	var sim := TestHelpers.duel()
	var shooter := sim.ships[0]
	shooter.command.fire = true
	shooter.command.aim = shooter.position + Vector2(-100, 0)
	sim.step(DT)
	assert_eq(sim.projectiles.size(), 0, "target is behind the 90-degree arc")


func test_projectile_hits_enemy_and_damages_hull() -> void:
	var sim := TestHelpers.duel()
	var shooter := sim.ships[0]
	var target := sim.ships[1]
	shooter.command.fire = true
	shooter.command.aim = target.position
	_run(sim, 1.0)
	assert_lt(target.hull_points, 1000.0, "target took damage")
	assert_lt(target.armor[ShipState.Quadrant.FRONT], 100.0, "front armour was struck")
	assert_eq(sim.ships[0].hull_points, 1000.0, "shooter untouched")


func test_shielded_target_takes_flux_not_damage() -> void:
	var sim := TestHelpers.duel()
	var shooter := sim.ships[0]
	var target := sim.ships[1]
	shooter.command.fire = true
	shooter.command.aim = target.position
	target.command.shield = true
	_run(sim, 0.6)
	assert_eq(target.hull_points, 1000.0)
	assert_gt(target.flux, 0.0)


func test_flux_dissipates_and_venting_is_faster() -> void:
	var sim := TestHelpers.duel()
	var a := sim.ships[0]
	var b := sim.ships[1]
	a.flux = 600.0
	b.flux = 600.0
	b.command.vent = true
	_run(sim, 1.0)
	assert_almost(a.flux, 500.0, 1.0, "100/s dissipation")
	assert_almost(b.flux, 300.0, 1.0, "3x while venting")
	assert_true(b.venting)
	assert_false(b.shield_up, "venting drops the shield")
	b.command.shield = true
	sim.step(DT)
	assert_false(b.shield_up, "cannot raise the shield while venting")


func test_overloaded_ship_cannot_fire_or_shield() -> void:
	var sim := TestHelpers.duel()
	var ship := sim.ships[0]
	ship.overload_left = 2.0
	ship.command.fire = true
	ship.command.shield = true
	ship.command.aim = sim.ships[1].position
	sim.step(DT)
	assert_eq(sim.projectiles.size(), 0)
	assert_false(ship.shield_up)
	_run(sim, 2.1)
	assert_false(ship.is_overloaded(), "overload ends")


func test_ship_moves_and_turns_toward_command() -> void:
	var sim := CombatSim.new()
	var ship := sim.add_ship(TestHelpers.hull(), {}, 0, Vector2.ZERO, 0.0)
	ship.command.move = Vector2(0, 1)
	_run(sim, 2.0)
	assert_gt(ship.position.y, 100.0, "moved along +Y")
	assert_almost(ship.velocity.length(), 100.0, 0.5, "at max speed")
	assert_almost(ship.heading, PI * 0.5, 0.01, "faces the way it moves")


func test_ship_stays_inside_arena() -> void:
	var sim := CombatSim.new()
	var ship := sim.add_ship(TestHelpers.hull(), {}, 0, Vector2(1100, 0), 0.0)
	ship.command.move = Vector2(1, 0)
	_run(sim, 3.0)
	assert_lt(ship.position.x, sim.arena.end.x, "clamped inside")
	assert_true(ship.in_battle())


func test_retreating_ship_escapes_at_the_edge() -> void:
	var sim := TestHelpers.duel()
	var runner := sim.ships[1]
	runner.retreating = true
	runner.command.move = Vector2(1, 0)
	_run(sim, 15.0)
	assert_true(runner.escaped)
	assert_true(runner.alive, "escaped ships are not destroyed")
	assert_eq(sim.outcome().winner, 0, "the player wins when every enemy has left")


func test_outcome_after_kill() -> void:
	var sim := TestHelpers.duel({"damage": 5000.0, "damage_type": WeaponData.DamageType.HIGH_EXPLOSIVE})
	var shooter := sim.ships[0]
	shooter.command.fire = true
	shooter.command.aim = sim.ships[1].position
	assert_true(sim.outcome().is_empty(), "undecided at start")
	_run(sim, 1.0)
	assert_false(sim.ships[1].alive)
	assert_eq(sim.outcome().winner, 0)


func test_determinism() -> void:
	var results: Array[Vector2] = []
	for _round in 2:
		var sim := TestHelpers.duel()
		for ship in sim.ships:
			ship.command.fire = true
			ship.command.shield = true
			ship.command.move = Vector2(0, 1)
		for _i in 120:
			for ship in sim.ships:
				ship.command.aim = sim.nearest_enemy(ship).position
			sim.step(DT)
		results.append(sim.ships[1].position + Vector2(sim.ships[1].hull_points, sim.ships[1].flux))
	assert_eq(results[0], results[1], "same inputs, same battle")
