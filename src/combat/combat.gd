extends Node2D
## Combat mode root (FR-CBT-1/6/9, FR-UX-2). Builds a CombatSim from
## GameState.battle, steps it at the physics rate, mirrors it into ShipViews
## and effects, turns touch input into the player's ShipCommand, and hands
## the result back through EventBus.battle_ended.
##
## Controls: the virtual joystick (or, in tap mode, a tapped point) moves the
## ship; the ship always faces its target so guns and shield point at it.
## Tap an enemy to make it the target. FIRE, SHIELD and VENT are toggles.

const TAP_SLOP := 16.0
const TAP_MAX_MS := 350
const TARGET_TAP_RADIUS := 70.0
const MOVE_ARRIVE_RADIUS := 24.0
const DEPLOY_X := 520.0
const DEPLOY_SPACING := 120.0
const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.0
const ShipViewScript := preload("res://src/combat/ship_view.gd")

var sim := CombatSim.new()

var _player: ShipState
var _target: ShipState
var _scheme: Settings.ControlScheme = Settings.ControlScheme.JOYSTICK
var _move_target: Vector2 = Vector2.ZERO
var _has_move_target: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _press_ms: int = 0
var _press_index: int = -1
var _result: Dictionary = {}

@onready var _effects: Node2D = $Effects
@onready var _ships: Node2D = $Ships
@onready var _camera: Camera2D = $Camera
@onready var _safe_area: MarginContainer = $HUD/SafeArea
@onready var _pause_button: Button = $HUD/SafeArea/Root/TopBar/Pause
@onready var _hull_bar: ProgressBar = $HUD/SafeArea/Root/TopBar/PlayerBars/Hull
@onready var _flux_bar: ProgressBar = $HUD/SafeArea/Root/TopBar/PlayerBars/Flux
@onready var _status: Label = $HUD/SafeArea/Root/TopBar/PlayerBars/Status
@onready var _target_name: Label = $HUD/SafeArea/Root/TopBar/TargetBars/Name
@onready var _target_hull: ProgressBar = $HUD/SafeArea/Root/TopBar/TargetBars/Hull
@onready var _target_flux: ProgressBar = $HUD/SafeArea/Root/TopBar/TargetBars/Flux
@onready var _joystick: TouchJoystick = $HUD/SafeArea/Root/Joystick
@onready var _hint: Label = $HUD/SafeArea/Root/Hint
@onready var _fire_button: Button = $HUD/SafeArea/Root/Buttons/Fire
@onready var _shield_button: Button = $HUD/SafeArea/Root/Buttons/Shield
@onready var _vent_button: Button = $HUD/SafeArea/Root/Buttons/Vent
@onready var _pause_menu: Control = $HUD/PauseMenu
@onready var _settings_menu: Control = $HUD/SettingsMenu
@onready var _result_screen: Control = $HUD/BattleResult


func _ready() -> void:
	_build(GameState.battle)
	_effects.sim = sim
	_camera.follow_target = _ships.get_child(0) if _ships.get_child_count() > 0 else null
	_camera.global_position = _player.position if _player != null else Vector2.ZERO
	_scheme = Settings.control_scheme
	_joystick.visible = _scheme == Settings.ControlScheme.JOYSTICK
	_hint.visible = _scheme == Settings.ControlScheme.TAP
	_style_bars()
	_pause_button.pressed.connect(_open_pause)
	_pause_menu.set_quit_label("Retreat")
	_pause_menu.resumed.connect(_pause_menu.close)
	_pause_menu.settings_requested.connect(_settings_menu.open)
	_pause_menu.quit_requested.connect(_retreat)
	_settings_menu.closed.connect(_apply_scheme)
	_result_screen.continued.connect(_leave)
	EventBus.back_requested.connect(_on_back_requested)
	SafeArea.apply(_safe_area)
	get_tree().root.size_changed.connect(func() -> void: SafeArea.apply(_safe_area))
	EventBus.battle_started.emit(GameState.battle)


func _notification(what: int) -> void:
	# Combat pauses itself the moment the screen is lost (FR-CBT-9).
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_inside_tree() and not get_tree().paused and _result.is_empty():
			_open_pause()


# --- setup ----------------------------------------------------------------


## Creates the ships of both sides from a battle context:
## {"player": [{"hull": id, "fit": {slot: weapon}}], "enemy": [...], "return_to": scene}.
func _build(context: Dictionary) -> void:
	var player_specs: Array = context.get("player", [])
	var enemy_specs: Array = context.get("enemy", [])
	for i in player_specs.size():
		var ship := _spawn(player_specs[i], 0, Vector2(-DEPLOY_X, _deploy_y(i, player_specs.size())), 0.0)
		if _player == null:
			_player = ship
	for i in enemy_specs.size():
		_spawn(enemy_specs[i], 1, Vector2(DEPLOY_X, _deploy_y(i, enemy_specs.size())), PI)


func _deploy_y(index: int, count: int) -> float:
	return (index - (count - 1) * 0.5) * DEPLOY_SPACING


func _spawn(spec: Dictionary, side: int, position: Vector2, heading: float) -> ShipState:
	var hull: HullData = DataRegistry.get_entry("hulls", str(spec.get("hull", "")))
	if hull == null:
		push_error("Combat: unknown hull %s" % spec.get("hull"))
		return null
	var fit := {}
	var fit_ids: Dictionary = spec.get("fit", {})
	for slot_id: String in fit_ids:
		var weapon: WeaponData = DataRegistry.get_entry("weapons", str(fit_ids[slot_id]))
		if weapon != null:
			fit[slot_id] = weapon
	var ship := sim.add_ship(hull, fit, side, position, heading)
	var view: Node2D = ShipViewScript.new()
	view.state = ship
	view.name = "Ship%d" % ship.id
	_ships.add_child(view)
	return ship


func _style_bars() -> void:
	for bar: ProgressBar in [_hull_bar, _target_hull]:
		bar.add_theme_stylebox_override("fill", _bar_style(Color(0.45, 0.85, 0.5)))
	for bar: ProgressBar in [_flux_bar, _target_flux]:
		bar.add_theme_stylebox_override("fill", _bar_style(Color(1.0, 0.6, 0.25)))


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


# --- loop -----------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if not _result.is_empty() or _player == null:
		return
	_player.command = _player_command()
	for ship in sim.ships:
		if ship.side != 0 and ship.in_battle():
			ship.command = ShipAI.decide(ship, sim)
	sim.step(delta)
	_effects.add_hits(sim.hits)
	_update_hud()
	var outcome := sim.outcome()
	if not outcome.is_empty():
		_finish("victory" if outcome.winner == 0 else "defeat")


func _process(delta: float) -> void:
	if _player == null:
		return
	# Zoom out just enough to keep the target on screen.
	var target := _current_target()
	var zoom := MAX_ZOOM
	if target != null:
		var distance := _player.position.distance_to(target.position)
		zoom = clampf(360.0 / (distance * 0.5 + 220.0), MIN_ZOOM, MAX_ZOOM)
	var z: float = lerpf(_camera.zoom.x, zoom, minf(1.0, 3.0 * delta))
	_camera.zoom = Vector2(z, z)


func _current_target() -> ShipState:
	if _target != null and not _target.in_battle():
		_target = null
	return _target if _target != null else sim.nearest_enemy(_player)


func _player_command() -> ShipCommand:
	var cmd := ShipCommand.new()
	if _scheme == Settings.ControlScheme.JOYSTICK:
		cmd.move = _joystick.vector
	elif _has_move_target:
		var to_target := _move_target - _player.position
		if to_target.length() < MOVE_ARRIVE_RADIUS:
			_has_move_target = false
		else:
			cmd.move = to_target.normalized()
	var target := _current_target()
	if target != null:
		cmd.face = (target.position - _player.position).normalized()
		cmd.aim = ShipAI.lead_point(_player, target)
		var in_reach := _player.position.distance_to(target.position) <= _player.max_weapon_range() * 1.2
		cmd.fire = _fire_button.button_pressed and in_reach
	cmd.shield = _shield_button.button_pressed
	cmd.vent = _vent_button.button_pressed
	return cmd


func _update_hud() -> void:
	_hull_bar.value = _player.hull_fraction() * 100.0
	_flux_bar.value = _player.flux_fraction() * 100.0
	if _player.is_overloaded():
		_status.text = "OVERLOADED"
	elif _player.venting:
		_status.text = "VENTING"
	else:
		_status.text = "%s" % _player.hull.display_name
	if _vent_button.button_pressed and _player.flux <= 0.0:
		_vent_button.button_pressed = false
	var target := _current_target()
	_target_name.get_parent().visible = target != null
	if target != null:
		_target_name.text = target.hull.display_name
		_target_hull.value = target.hull_fraction() * 100.0
		_target_flux.value = target.flux_fraction() * 100.0


# --- input ----------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _press_index == -1:
			_press_index = event.index
			_press_position = event.position
			_press_ms = Time.get_ticks_msec()
		elif not event.pressed and event.index == _press_index:
			_press_index = -1
			var quick := Time.get_ticks_msec() - _press_ms <= TAP_MAX_MS
			if quick and event.position.distance_to(_press_position) <= TAP_SLOP:
				_tap(_camera.screen_to_world(event.position))
		get_viewport().set_input_as_handled()


func _tap(world: Vector2) -> void:
	var enemy := _enemy_near(world)
	if enemy != null:
		_target = enemy
		return
	if _scheme == Settings.ControlScheme.TAP:
		_move_target = world
		_has_move_target = true


func _enemy_near(world: Vector2) -> ShipState:
	var best: ShipState = null
	var best_distance := TARGET_TAP_RADIUS
	for ship in sim.ships:
		if ship.side == 0 or not ship.in_battle():
			continue
		var d := ship.position.distance_to(world) - ship.radius
		if d < best_distance:
			best_distance = d
			best = ship
	return best


func _apply_scheme() -> void:
	_scheme = Settings.control_scheme
	_joystick.visible = _scheme == Settings.ControlScheme.JOYSTICK
	_hint.visible = _scheme == Settings.ControlScheme.TAP
	_has_move_target = false


# --- overlays and transitions ---------------------------------------------


func _on_back_requested() -> void:
	if not _result.is_empty():
		return
	if _settings_menu.visible:
		_settings_menu.close()
	elif _pause_menu.visible:
		_pause_menu.close()
	else:
		_open_pause()


func _open_pause() -> void:
	_pause_menu.open()


func _retreat() -> void:
	_pause_menu.close()
	_finish("retreat")


func _finish(outcome: String) -> void:
	var ships: Array = []
	for ship in sim.ships:
		ships.append(ship.to_dict())
	_result = {
		"outcome": outcome,
		"time": sim.time,
		"ships": ships,
		"return_to": GameState.battle.get("return_to", "main_menu"),
	}
	_result_screen.show_result(_result)


func _leave() -> void:
	get_tree().paused = false
	EventBus.battle_ended.emit(_result)
	SceneRouter.go(str(_result.return_to))
