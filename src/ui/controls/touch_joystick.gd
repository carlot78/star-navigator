class_name TouchJoystick
extends Control
## Touch joystick (FR-UX-2; not the engine's VirtualJoystick): the finger that lands on this control drags a
## knob around the centre; `vector` is the knob offset normalised to -1..1.
## Drawn procedurally; sized by the scene.

const KNOB_RADIUS := 34.0
const BASE_COLOR := Color(0.5, 0.6, 0.9, 0.18)
const RING_COLOR := Color(0.6, 0.72, 1.0, 0.45)
const KNOB_COLOR := Color(0.75, 0.85, 1.0, 0.75)

## Direction and throttle, length 0..1.
var vector: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _knob: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_update(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update(event.position)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release()


func _radius() -> float:
	return minf(size.x, size.y) * 0.5 - KNOB_RADIUS * 0.5


func _update(local: Vector2) -> void:
	var offset := (local - size * 0.5).limit_length(_radius())
	_knob = offset
	vector = offset / _radius()
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_knob = Vector2.ZERO
	vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	var radius := _radius()
	draw_circle(centre, radius + KNOB_RADIUS * 0.5, BASE_COLOR)
	draw_arc(centre, radius, 0.0, TAU, 48, RING_COLOR, 2.0, true)
	draw_circle(centre + _knob, KNOB_RADIUS, KNOB_COLOR)
