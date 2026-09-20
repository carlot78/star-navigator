class_name ShipMover
extends RefCounted
## Pure movement model for a campaign ship: turn toward a target, accelerate,
## and arrive without overshooting. Holds no nodes; whoever renders the ship
## calls step() every physics tick and copies position/heading out.

const ARRIVE_DISTANCE := 4.0

var position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
## Radians, 0 = +X (the direction the sprite faces).
var heading: float = 0.0
var target: Vector2 = Vector2.ZERO
var has_target: bool = false
## True on the last step where the engine pushed (for the exhaust effect).
var thrusting: bool = false

var max_speed: float = 140.0
var acceleration: float = 100.0
## Degrees per second.
var turn_rate: float = 80.0


func configure(hull: HullData) -> void:
	max_speed = hull.max_speed
	acceleration = hull.acceleration
	turn_rate = hull.turn_rate


func set_target(point: Vector2) -> void:
	target = point
	has_target = true


func clear_target() -> void:
	has_target = false


func is_moving() -> bool:
	return has_target or velocity.length_squared() > 1.0


func step(delta: float) -> void:
	var desired := Vector2.ZERO
	if has_target:
		var to_target := target - position
		var distance := to_target.length()
		# Snap when the next step would cross the target.
		if distance <= maxf(ARRIVE_DISTANCE, velocity.length() * delta * 1.5):
			position = target
			velocity = Vector2.ZERO
			has_target = false
		else:
			# Fastest speed that can still be shed before arrival: v = sqrt(2·a·d).
			var speed := minf(max_speed, sqrt(2.0 * acceleration * distance))
			desired = to_target / distance * speed
	thrusting = desired.distance_squared_to(velocity) > 1.0
	velocity = velocity.move_toward(desired, acceleration * delta)
	position += velocity * delta
	var face := velocity
	if face.length_squared() <= 1.0 and has_target:
		face = target - position
	if face.length_squared() > 0.0:
		heading = rotate_toward(heading, face.angle(), deg_to_rad(turn_rate) * delta)
