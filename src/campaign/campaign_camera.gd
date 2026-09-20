extends Camera2D
## Campaign camera: follows the player ship until the player pans, zooms
## around a screen anchor (pinch midpoint or mouse pointer), and can be
## re-attached with recenter().

signal follow_changed(following: bool)

const MIN_ZOOM := 0.4
const MAX_ZOOM := 2.5
const FOLLOW_SPEED := 6.0

var follow_target: Node2D
var following: bool = true:
	set(value):
		if following != value:
			following = value
			follow_changed.emit(value)


func _process(delta: float) -> void:
	if following and follow_target != null:
		global_position = global_position.lerp(follow_target.global_position, minf(1.0, FOLLOW_SPEED * delta))


## Moves the view by a screen-space delta (finger drag), detaching from the ship.
func pan_by(screen_delta: Vector2) -> void:
	following = false
	global_position -= screen_delta / zoom.x


## Multiplies the zoom, keeping the world point under screen_anchor fixed.
func zoom_by(factor: float, screen_anchor: Vector2) -> void:
	var before := screen_to_world(screen_anchor)
	var z := clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(z, z)
	global_position += before - screen_to_world(screen_anchor)


func recenter() -> void:
	following = true


func screen_to_world(screen: Vector2) -> Vector2:
	var half := get_viewport_rect().size * 0.5
	return global_position + (screen - half) / zoom.x


func world_to_screen(world: Vector2) -> Vector2:
	var half := get_viewport_rect().size * 0.5
	return (world - global_position) * zoom.x + half
