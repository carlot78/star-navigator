extends Node2D
## Campaign mode root: the star system view the player flies around in.
## Turns touches into ship courses and camera moves, hosts the HUD and the
## pause/settings overlays, and saves at every safe transition.
##
## Touch grammar (FR-CMP-2, FR-UX-1):
##   tap on empty space      → fly there
##   drag starting on ship   → drag a course; the ship follows the finger
##   drag on empty space     → pan the camera (detaches from the ship)
##   two fingers             → pinch to zoom
##   mouse wheel (desktop)   → zoom

enum Gesture { NONE, TAP, PAN, COURSE, PINCH }

const TAP_SLOP := 14.0
const TAP_MAX_MS := 400
const COURSE_GRAB_RADIUS := 44.0
const COURSE_COLOR := Color(0.6, 0.8, 1.0, 0.7)

@onready var _system: Node2D = $StarSystem
@onready var _ship: Node2D = $PlayerShip
@onready var _camera: Camera2D = $Camera
@onready var _status: Label = $HUD/SafeArea/TopBar/Status
@onready var _menu_button: Button = $HUD/SafeArea/TopBar/Menu
@onready var _recenter_button: Button = $HUD/SafeArea/TopBar/Recenter
@onready var _top_bar: Control = $HUD/SafeArea/TopBar
@onready var _safe_area: MarginContainer = $HUD/SafeArea
@onready var _pause_menu: Control = $HUD/PauseMenu
@onready var _settings_menu: Control = $HUD/SettingsMenu

var _gesture: Gesture = Gesture.NONE
var _touches: Dictionary = {}
var _press_position: Vector2 = Vector2.ZERO
var _press_ms: int = 0
var _pinch_distance: float = 0.0


func _ready() -> void:
	_camera.follow_target = _ship
	_camera.follow_changed.connect(func(following: bool) -> void: _recenter_button.visible = not following)
	_recenter_button.visible = false
	_recenter_button.pressed.connect(_camera.recenter)
	_menu_button.pressed.connect(_open_pause)
	_pause_menu.resumed.connect(_pause_menu.close)
	_pause_menu.settings_requested.connect(_settings_menu.open)
	_pause_menu.quit_requested.connect(_save_and_quit)
	EventBus.back_requested.connect(_on_back_requested)
	EventBus.day_passed.connect(func(_day: int) -> void: _refresh_status())
	SafeArea.apply(_safe_area)
	get_tree().root.size_changed.connect(func() -> void: SafeArea.apply(_safe_area))
	_refresh_status()


func _process(_delta: float) -> void:
	queue_redraw()


func _notification(what: int) -> void:
	# Losing the screen mid-flight must never lose progress (NFR-5).
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_inside_tree() and not get_tree().paused:
			_open_pause()


# --- input ---------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_touch_move(event.index, event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom_by(1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom_by(1.0 / 1.15, event.position)


func _touch_down(index: int, screen: Vector2) -> void:
	if _top_bar.get_global_rect().has_point(screen):
		return
	_touches[index] = screen
	if _touches.size() >= 2:
		_gesture = Gesture.PINCH
		_pinch_distance = _pinch_span()
		return
	_press_position = screen
	_press_ms = Time.get_ticks_msec()
	var ship_on_screen: Vector2 = _camera.world_to_screen(_ship.global_position)
	_gesture = Gesture.COURSE if ship_on_screen.distance_to(screen) <= COURSE_GRAB_RADIUS else Gesture.TAP


func _touch_move(index: int, screen: Vector2) -> void:
	if not _touches.has(index):
		return
	var previous: Vector2 = _touches[index]
	_touches[index] = screen
	match _gesture:
		Gesture.PINCH:
			var span := _pinch_span()
			if _pinch_distance > 0.0 and span > 0.0:
				_camera.zoom_by(span / _pinch_distance, _pinch_midpoint())
			_pinch_distance = span
		Gesture.TAP:
			if screen.distance_to(_press_position) > TAP_SLOP:
				_gesture = Gesture.PAN
				_camera.pan_by(screen - _press_position)
		Gesture.PAN:
			_camera.pan_by(screen - previous)
		Gesture.COURSE:
			_set_course(screen)


func _touch_up(index: int, screen: Vector2) -> void:
	if not _touches.has(index):
		return
	_touches.erase(index)
	match _gesture:
		Gesture.TAP:
			if Time.get_ticks_msec() - _press_ms <= TAP_MAX_MS:
				_set_course(screen)
				_camera.recenter()
		Gesture.COURSE:
			_set_course(screen)
		Gesture.PINCH:
			if _touches.size() == 1:
				_gesture = Gesture.PAN
				return
	if _touches.is_empty():
		_gesture = Gesture.NONE


func _set_course(screen: Vector2) -> void:
	_ship.move_to(_system.clamp_point(_camera.screen_to_world(screen)))


func _pinch_span() -> float:
	var points: Array = _touches.values()
	return (points[0] as Vector2).distance_to(points[1]) if points.size() >= 2 else 0.0


func _pinch_midpoint() -> Vector2:
	var points: Array = _touches.values()
	return ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5


# --- overlays and transitions ---------------------------------------------


func _on_back_requested() -> void:
	if _settings_menu.visible:
		_settings_menu.close()
	elif _pause_menu.visible:
		_pause_menu.close()
	else:
		_open_pause()


func _open_pause() -> void:
	_save()
	_pause_menu.open()


func _save_and_quit() -> void:
	_save()
	get_tree().paused = false
	SceneRouter.go("main_menu")


func _save() -> void:
	_ship.write_state()
	SaveService.save_game()


func _refresh_status() -> void:
	_status.text = "Day %d  ·  %d cr" % [GameState.day, GameState.credits]


func _draw() -> void:
	var mover: ShipMover = _ship.mover
	if not mover.has_target:
		return
	draw_dashed_line(_ship.position, mover.target, COURSE_COLOR, 1.5, 12.0)
	draw_arc(mover.target, 10.0, 0.0, TAU, 24, COURSE_COLOR, 1.5, true)
