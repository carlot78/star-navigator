extends TestCase
## ShipMover (campaign movement model).


func test_arrives_without_overshoot() -> void:
	var mover := ShipMover.new()
	mover.max_speed = 140.0
	mover.acceleration = 100.0
	mover.turn_rate = 80.0
	mover.set_target(Vector2(500.0, 0.0))
	var peak := 0.0
	for _i in 60 * 12:
		mover.step(1.0 / 60.0)
		peak = maxf(peak, mover.velocity.length())
	assert_false(mover.has_target, "reaches its target within 12 s")
	assert_lt(mover.position.distance_to(Vector2(500.0, 0.0)), 1.0, "stops on the target")
	assert_lt(peak, 140.01, "never exceeds max speed")
	assert_almost(mover.heading, 0.0, 0.01, "faces +X after flying along +X")


func test_configure_reads_hull_stats() -> void:
	var mover := ShipMover.new()
	mover.configure(TestHelpers.hull({"max_speed": 55.0, "acceleration": 22.0, "turn_rate": 11.0}))
	assert_eq(mover.max_speed, 55.0)
	assert_eq(mover.acceleration, 22.0)
	assert_eq(mover.turn_rate, 11.0)
