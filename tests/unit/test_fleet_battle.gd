extends TestCase
## M3 model behaviour: orders, retreat edges, separation, deployment and
## whole fleet battles run by the AI on both sides.

const DT := 1.0 / 60.0


func _hull_lookup(id: String) -> HullData:
	return TestHelpers.hull({"id": id})


func _weapon_lookup(id: String) -> WeaponData:
	return TestHelpers.weapon({"id": id})


func _fleet_context(per_side: int) -> Dictionary:
	var spec := {"hull": "h", "fit": {"gun": "g"}, "count": per_side}
	return {"player": [spec], "enemy": [spec], "arena": [3000, 2000]}


func _run_ai(sim: CombatSim, max_seconds: float) -> void:
	for _i in int(max_seconds / DT):
		for ship in sim.ships:
			if ship.in_battle():
				ship.command = ShipAI.decide(ship, sim)
		sim.step(DT)
		if not sim.outcome().is_empty():
			return


# --- deployment -------------------------------------------------------------


func test_builder_expands_counts_and_sides() -> void:
	var sim := CombatSim.new()
	var context := {"player": [{"hull": "a", "count": 3}], "enemy": [{"hull": "b"}, {"hull": "c", "count": 2}]}
	var ships := BattleBuilder.populate(sim, context, _hull_lookup, _weapon_lookup)
	assert_eq(ships.size(), 6)
	assert_eq(sim.ships_in_battle(0).size(), 3)
	assert_eq(sim.ships_in_battle(1).size(), 3)
	assert_eq(ships[3].hull.id, "b", "specs keep their order")


func test_builder_deploys_on_own_half_without_overlap() -> void:
	var sim := CombatSim.new()
	BattleBuilder.populate(sim, _fleet_context(10), _hull_lookup, _weapon_lookup)
	assert_eq(sim.arena.size, Vector2(3000, 2000), "arena from context")
	for ship in sim.ships:
		assert_true(sim.arena.has_point(ship.position), "inside the arena")
		if ship.side == 0:
			assert_lt(ship.position.x, 0.0, "player ships on the left")
		else:
			assert_gt(ship.position.x, 0.0, "enemy ships on the right")
	for i in sim.ships.size():
		for j in range(i + 1, sim.ships.size()):
			var a := sim.ships[i]
			var b := sim.ships[j]
			assert_gt(a.position.distance_to(b.position), a.radius + b.radius, "no overlap at deployment")


func test_builder_fits_weapons_by_slot() -> void:
	var sim := CombatSim.new()
	var ships := BattleBuilder.populate(sim, {"player": [{"hull": "a", "fit": {"gun": "g", "none": "g"}}]},
		_hull_lookup, _weapon_lookup)
	assert_eq(ships[0].mounts.size(), 1, "only slots the hull has are fitted")


# --- orders -----------------------------------------------------------------


func test_engage_order_prefers_the_ordered_target() -> void:
	var sim := CombatSim.new()
	var ally := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 0, Vector2(-200, 0), 0.0)
	sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(0, 0), PI)
	var far := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(800, 400), PI)
	assert_eq(ShipAI.choose_target(ally, sim), sim.ships[1], "nearest by default")
	ally.give_order(ShipState.Order.ENGAGE, far.id)
	assert_eq(ShipAI.choose_target(ally, sim), far, "ordered target")
	far.alive = false
	assert_eq(ShipAI.choose_target(ally, sim), sim.ships[1], "falls back to nearest when the target is gone")


func test_defend_holds_station_when_nothing_is_near() -> void:
	var sim := CombatSim.new()
	var ally := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 0, Vector2(-500, 0), 0.0)
	sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(1100, 0), PI)
	ally.give_order(ShipState.Order.DEFEND, -1, Vector2(-500, -400))
	assert_eq(ShipAI.choose_target(ally, sim), null, "the enemy is far from the point")
	var cmd := ShipAI.decide(ally, sim)
	assert_lt(cmd.move.y, 0.0, "moves toward the defend point")
	assert_false(cmd.fire)
	ally.position = Vector2(-500, -390)
	assert_eq(ShipAI.decide(ally, sim).move, Vector2.ZERO, "stays put once on station")


func test_defend_engages_enemies_near_the_point() -> void:
	var sim := CombatSim.new()
	var ally := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 0, Vector2(-500, 0), 0.0)
	var raider := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(-100, 0), PI)
	ally.give_order(ShipState.Order.DEFEND, -1, Vector2(-400, 0))
	assert_eq(ShipAI.choose_target(ally, sim), raider)
	assert_true(ShipAI.decide(ally, sim).fire)


func test_retreat_order_heads_for_own_edge() -> void:
	var sim := TestHelpers.duel()
	var ship := sim.ships[0]
	ship.give_order(ShipState.Order.RETREAT)
	assert_true(ship.retreating)
	var cmd := ShipAI.decide(ship, sim)
	assert_eq(cmd.move, Vector2.LEFT, "player side leaves by the left edge")
	assert_gt(cmd.face.x, 0.0, "keeps facing the enemy")


func test_retreat_escapes_only_at_own_edge() -> void:
	var sim := TestHelpers.duel()
	var ship := sim.ships[0]
	ship.retreating = true
	ship.position = Vector2(1100, 400)
	ship.command.move = Vector2.RIGHT
	for _i in 120:
		sim.step(DT)
	assert_false(ship.escaped, "the enemy edge is a wall")
	ship.command.move = Vector2.LEFT
	for _i in int(30.0 / DT):
		sim.step(DT)
		if ship.escaped:
			break
	assert_true(ship.escaped, "the own edge lets it out")


func test_outcome_reports_retreat_and_defeat() -> void:
	var sim := TestHelpers.duel()
	sim.ships[0].escaped = true
	assert_eq(sim.outcome().result, "retreat")
	sim.ships[0].escaped = false
	sim.ships[0].alive = false
	assert_eq(sim.outcome().result, "defeat")
	sim.ships[0].alive = true
	sim.ships[1].escaped = true
	assert_eq(sim.outcome().result, "victory", "an enemy that fled is a win")


# --- physics ----------------------------------------------------------------


func test_overlapping_ships_are_pushed_apart() -> void:
	var sim := CombatSim.new()
	var a := sim.add_ship(TestHelpers.hull(), {}, 0, Vector2(0, 0), 0.0)
	var b := sim.add_ship(TestHelpers.hull(), {}, 0, Vector2(10, 0), 0.0)
	sim.step(DT)
	assert_gt(a.position.distance_to(b.position), a.radius + b.radius - 0.01)
	assert_lt(a.position.x, 0.0, "pushed symmetrically")


# --- whole battles ------------------------------------------------------------


func test_ten_versus_ten_reaches_an_outcome() -> void:
	var sim := CombatSim.new()
	BattleBuilder.populate(sim, _fleet_context(10), _hull_lookup, _weapon_lookup)
	_run_ai(sim, 240.0)
	assert_false(sim.outcome().is_empty(), "the AI fights to a result within 4 minutes (took %.0f s)" % sim.time)


func test_fleet_battle_is_deterministic() -> void:
	var fingerprints: Array[String] = []
	for _round in 2:
		var sim := CombatSim.new()
		BattleBuilder.populate(sim, _fleet_context(4), _hull_lookup, _weapon_lookup)
		_run_ai(sim, 30.0)
		var parts := PackedStringArray()
		for ship in sim.ships:
			parts.append("%.3f,%.3f,%.3f" % [ship.position.x, ship.position.y, ship.hull_points])
		fingerprints.append(",".join(parts))
	assert_eq(fingerprints[0], fingerprints[1], "same fleets, same battle")
