extends Node2D
## Draws one ShipState: a hull silhouette scaled to its size, the shield arc
## when raised, exhaust when thrusting, an overload flicker, and a small
## hull/flux readout under the ship. Reads the model every frame; holds no
## game state of its own.

const PLAYER_COLOR := Color(0.9, 0.93, 1.0)
const ENEMY_COLOR := Color(1.0, 0.62, 0.55)
const SHIELD_COLOR := Color(0.45, 0.75, 1.0, 0.85)
const EXHAUST_COLOR := Color(0.45, 0.65, 1.0, 0.9)
const OVERLOAD_COLOR := Color(1.0, 0.85, 0.3)
const BAR_BACK := Color(0, 0, 0, 0.55)
const HULL_BAR := Color(0.45, 0.85, 0.5)
const FLUX_BAR := Color(1.0, 0.6, 0.25)
## Unit silhouette, ship faces +X; scaled by the collision radius.
const SILHOUETTE := [
	Vector2(1.0, 0.0), Vector2(0.1, 0.55), Vector2(-0.6, 0.7), Vector2(-0.45, 0.0),
	Vector2(-0.6, -0.7), Vector2(0.1, -0.55),
]

var state: ShipState
var _flicker: float = 0.0


func _process(delta: float) -> void:
	if state == null:
		return
	position = state.position
	rotation = state.heading
	visible = state.in_battle()
	_flicker += delta * 12.0
	queue_redraw()


func _draw() -> void:
	if state == null:
		return
	var r := state.radius * 1.35
	var color := PLAYER_COLOR if state.side == 0 else ENEMY_COLOR
	if state.is_overloaded() and int(_flicker) % 2 == 0:
		color = OVERLOAD_COLOR
	var thrusting := state.velocity.length_squared() > 4.0 and state.command.move != Vector2.ZERO
	if thrusting:
		draw_colored_polygon(PackedVector2Array([Vector2(-0.5 * r, 0.3 * r), Vector2(-1.3 * r, 0.0),
			Vector2(-0.5 * r, -0.3 * r)]), EXHAUST_COLOR)
	var points := PackedVector2Array()
	for p: Vector2 in SILHOUETTE:
		points.append(p * r)
	draw_colored_polygon(points, color)
	points.append(points[0])
	draw_polyline(points, color.darkened(0.35), 1.5)
	if state.shield_up:
		var half := deg_to_rad(state.hull.shield_arc) * 0.5
		draw_arc(Vector2.ZERO, state.radius + 10.0, -half, half, 32, SHIELD_COLOR, 3.0, true)
	# Readout under the ship, drawn unrotated.
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	var width := r * 2.2
	var top := r + 14.0
	draw_rect(Rect2(-width * 0.5, top, width, 4.0), BAR_BACK)
	draw_rect(Rect2(-width * 0.5, top, width * state.hull_fraction(), 4.0), HULL_BAR)
	draw_rect(Rect2(-width * 0.5, top + 6.0, width, 4.0), BAR_BACK)
	draw_rect(Rect2(-width * 0.5, top + 6.0, width * state.flux_fraction(), 4.0), FLUX_BAR)
