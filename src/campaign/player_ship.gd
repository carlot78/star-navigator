extends Node2D
## The player's flagship in the campaign view. Owns a ShipMover (the model),
## steps it each physics tick and draws a placeholder hull until sprites
## arrive. Position and heading are written back to GameState.location
## through write_state() before every save.

const HULL_COLOR := Color(0.91, 0.93, 1.0)
const HULL_SHADE := Color(0.6, 0.66, 0.85)
const EXHAUST_COLOR := Color(0.45, 0.65, 1.0, 0.9)
const HULL_SHAPE := [
	Vector2(20, 0), Vector2(-4, 10), Vector2(-14, 12), Vector2(-9, 0), Vector2(-14, -12), Vector2(-4, -10),
]
const EXHAUST_SHAPE := [Vector2(-10, 5), Vector2(-26, 0), Vector2(-10, -5)]

var mover := ShipMover.new()


func _ready() -> void:
	var hull: HullData = DataRegistry.get_entry("hulls", GameState.flagship_hull_id())
	if hull != null:
		mover.configure(hull)
	mover.position = GameState.location_position()
	mover.heading = float(GameState.location.get("heading", 0.0))
	position = mover.position
	rotation = mover.heading


func _physics_process(delta: float) -> void:
	var was_thrusting := mover.thrusting
	mover.step(delta)
	position = mover.position
	rotation = mover.heading
	if was_thrusting != mover.thrusting:
		queue_redraw()


func move_to(point: Vector2) -> void:
	mover.set_target(point)


## Copies the ship's state into GameState so a save reflects where it is.
func write_state() -> void:
	GameState.location["position"] = [mover.position.x, mover.position.y]
	GameState.location["heading"] = mover.heading


func _draw() -> void:
	var hull := PackedVector2Array(HULL_SHAPE)
	if mover.thrusting:
		draw_colored_polygon(PackedVector2Array(EXHAUST_SHAPE), EXHAUST_COLOR)
	draw_colored_polygon(hull, HULL_COLOR)
	hull.append(hull[0])
	draw_polyline(hull, HULL_SHADE, 1.5)
