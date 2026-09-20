extends TestCase
## ShipAI: approach, hold range, shield under fire, vent when safe, retreat.


func test_approaches_distant_target() -> void:
	var sim := CombatSim.new()
	var ai_ship := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(900, 0), PI)
	sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 0, Vector2(-900, 0), 0.0)
	var cmd := ShipAI.decide(ai_ship, sim)
	assert_lt(cmd.move.x, 0.0, "moves toward the enemy on the left")
	assert_false(cmd.fire, "out of range")
	assert_almost(absf(cmd.face.angle()), PI, 0.01, "faces the enemy")


func test_fires_in_range_and_backs_off_when_too_close() -> void:
	var sim := TestHelpers.duel()
	var ai_ship := sim.ships[1]
	var cmd := ShipAI.decide(ai_ship, sim)
	assert_true(cmd.fire, "300 px is within a 600 px gun")
	sim.ships[0].position = ai_ship.position + Vector2(-50, 0)
	cmd = ShipAI.decide(ai_ship, sim)
	assert_gt(cmd.move.x, 0.0, "backs away from a point-blank enemy")


func test_raises_shield_when_shots_are_inbound() -> void:
	var sim := CombatSim.new()
	var ai_ship := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(0, 0), PI)
	sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon({"range": 100.0})}, 0, Vector2(-2000, 0), 0.0)
	assert_false(ShipAI.decide(ai_ship, sim).shield, "no threat, no shield")
	var shot := ProjectileState.new()
	shot.position = Vector2(-300, 0)
	shot.velocity = Vector2(600, 0)
	shot.side = 0
	shot.life = 1.0
	sim.projectiles.append(shot)
	assert_true(ShipAI.decide(ai_ship, sim).shield, "incoming shot raises the shield")


func test_vents_when_high_flux_and_safe() -> void:
	var sim := CombatSim.new()
	var ai_ship := sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon()}, 1, Vector2(0, 0), PI)
	sim.add_ship(TestHelpers.hull(), {"gun": TestHelpers.weapon({"range": 100.0})}, 0, Vector2(-500, 0), 0.0)
	ai_ship.flux = 800.0
	var cmd := ShipAI.decide(ai_ship, sim)
	assert_true(cmd.vent)
	assert_false(cmd.fire, "no firing while venting")


func test_retreats_on_low_hull() -> void:
	var sim := TestHelpers.duel()
	var ai_ship := sim.ships[1]
	ai_ship.hull_points = 100.0
	var cmd := ShipAI.decide(ai_ship, sim)
	assert_true(ai_ship.retreating)
	assert_gt(cmd.move.x, 0.0, "moves away from the enemy on the left")
	assert_true(cmd.shield, "keeps the shield toward the enemy while leaving")
	assert_lt(cmd.face.x, 0.0, "still faces the enemy")


func test_lead_point_accounts_for_target_velocity() -> void:
	var sim := TestHelpers.duel()
	sim.ships[1].velocity = Vector2(0, 100)
	var lead := ShipAI.lead_point(sim.ships[0], sim.ships[1])
	assert_gt(lead.y, sim.ships[1].position.y, "aims ahead of a target moving down")
