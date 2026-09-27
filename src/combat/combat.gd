extends Node2D
## Combat mode root (FR-CBT-1/5/6/9, FR-UX-2). Builds a CombatSim from
## GameState.battle, steps it at the physics rate, mirrors it into ShipViews
## and effects, turns touch input into the flagship's ShipCommand, and hands
## the result back through EventBus.battle_ended.
##
## Phases: DEPLOY (pick the flagship, fleets only) → FIGHT ⇄ COMMAND (sim
## frozen, give orders to escorts) → OVER (result overlay).
##
## Controls in FIGHT: the joystick (or, in tap mode, a tapped point) moves the
## flagship; it always faces its target so guns and shield point at it. Tap
## an enemy to target it. FIRE, SHIELD and VENT are toggles.

enum Phase { DEPLOY, FIGHT, COMMAND, OVER }

const TAP_SLOP := 16.0
const TAP_MAX_MS := 350
const TARGET_TAP_RADIUS := 70.0
const MOVE_ARRIVE_RADIUS := 24.0
const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.0
## Zoom limits when framing the whole battle (deployment and command view).
const OVERVIEW_MIN_ZOOM := 0.22
const OVERVIEW_MARGIN := 260.0
const TOAST_SECONDS := 2.5
const PERF_REFRESH_SECONDS := 0.5
const ShipViewScript := preload("res://src/combat/ship_view.gd")

var sim := CombatSim.new()

var _phase: Phase = Phase.FIGHT
var _player: ShipState
var _target: ShipState
var _views: Dictionary = {}
var _scheme: Settings.ControlScheme = Settings.ControlScheme.JOYSTICK
var _move_target: Vector2 = Vector2.ZERO
var _has_move_target: bool = false
var _press_position: Vector2 = Vector2.ZERO
var _press_ms: int = 0
var _press_index: int = -1
var _result: Dictionary = {}
# Command view
var _selected: ShipState
## Order waiting for a tap: -1 none, else ShipState.Order.ENGAGE / DEFEND.
var _pending_order: int = -1
var _toast_left: float = 0.0
# Benchmark (NFR-1)
var _benchmark: bool = false
var _frames: int = 0
var _frame_time: float = 0.0
var _worst_frame: float = 0.0
var _sim_usec: int = 0
var _sim_steps: int = 0
var _peak_shots: int = 0
var _perf_window: Array[float] = []
var _perf_refresh: float = 0.0

@onready var _effects: Node2D = $Effects
@onready var _ships: Node2D = $Ships
@onready var _camera: Camera2D = $Camera
@onready var _safe_area: MarginContainer = $HUD/SafeArea
@onready var _pause_button: Button = $HUD/SafeArea/Root/TopBar/Pause
@onready var _orders_button: Button = $HUD/SafeArea/Root/TopBar/Orders
@onready var _hull_bar: ProgressBar = $HUD/SafeArea/Root/TopBar/PlayerBars/Hull
@onready var _flux_bar: ProgressBar = $HUD/SafeArea/Root/TopBar/PlayerBars/Flux
@onready var _status: Label = $HUD/SafeArea/Root/TopBar/PlayerBars/Status
@onready var _forces: Label = $HUD/SafeArea/Root/TopBar/Forces
@onready var _target_bars: Control = $HUD/SafeArea/Root/TopBar/TargetBars
@onready var _target_name: Label = $HUD/SafeArea/Root/TopBar/TargetBars/Name
@onready var _target_hull: ProgressBar = $HUD/SafeArea/Root/TopBar/TargetBars/Hull
@onready var _target_flux: ProgressBar = $HUD/SafeArea/Root/TopBar/TargetBars/Flux
@onready var _perf: Label = $HUD/SafeArea/Root/Perf
@onready var _toast: Label = $HUD/SafeArea/Root/Toast
@onready var _joystick: TouchJoystick = $HUD/SafeArea/Root/Joystick
@onready var _hint: Label = $HUD/SafeArea/Root/Hint
@onready var _buttons: Control = $HUD/SafeArea/Root/Buttons
@onready var _fire_button: Button = $HUD/SafeArea/Root/Buttons/Fire
@onready var _shield_button: Button = $HUD/SafeArea/Root/Buttons/Shield
@onready var _vent_button: Button = $HUD/SafeArea/Root/Buttons/Vent
@onready var _command_panel: Control = $HUD/SafeArea/Root/Command
@onready var _command_hint: Label = $HUD/SafeArea/Root/Command/VBox/Hint
@onready var _order_engage: Button = $HUD/SafeArea/Root/Command/VBox/Row/Engage
@onready var _order_defend: Button = $HUD/SafeArea/Root/Command/VBox/Row/Defend
@onready var _order_retreat: Button = $HUD/SafeArea/Root/Command/VBox/Row/Retreat
@onready var _order_full_retreat: Button = $HUD/SafeArea/Root/Command/VBox/Row/FullRetreat
@onready var _order_resume: Button = $HUD/SafeArea/Root/Command/VBox/Row/Resume
@onready var _deploy_panel: Control = $HUD/SafeArea/Root/Deploy
@onready var _deploy_ships: HBoxContainer = $HUD/SafeArea/Root/Deploy/Panel/VBox/Ships
@onready var _deploy_engage: Button = $HUD/SafeArea/Root/Deploy/Panel/VBox/Engage
@onready var _pause_menu: Control = $HUD/PauseMenu
@onready var _settings_menu: Control = $HUD/SettingsMenu
@onready var _result_screen: Control = $HUD/BattleResult


func _ready() -> void:
	var context: Dictionary = GameState.battle
	_benchmark = bool(context.get("benchmark", false))
	var ships := BattleBuilder.populate(sim, context,
		func(id: String) -> HullData: return DataRegistry.get_entry("hulls", id),
		func(id: String) -> WeaponData: return DataRegistry.get_entry("weapons", id))
	for ship in ships:
		var view: Node2D = ShipViewScript.new()
		view.state = ship
		view.name = "Ship%d" % ship.id
		_ships.add_child(view)
		_views[ship.id] = view
	_effects.sim = sim
	_perf.visible = _benchmark
	_toast.visible = false
	_style_bars()
	_scheme = Settings.control_scheme
	_pause_button.pressed.connect(_open_pause)
	_orders_button.pressed.connect(_enter_command)
	_order_engage.pressed.connect(_arm_order.bind(ShipState.Order.ENGAGE))
	_order_defend.pressed.connect(_arm_order.bind(ShipState.Order.DEFEND))
	_order_retreat.pressed.connect(_order_selected_retreat)
	_order_full_retreat.pressed.connect(_full_retreat)
	_order_resume.pressed.connect(_leave_command)
	_deploy_engage.pressed.connect(_start_fight)
	_pause_menu.set_quit_label("Full retreat")
	_pause_menu.resumed.connect(_pause_menu.close)
	_pause_menu.settings_requested.connect(_settings_menu.open)
	_pause_menu.quit_requested.connect(_retreat_from_pause)
	_settings_menu.closed.connect(_apply_scheme)
	_result_screen.continued.connect(_leave)
	EventBus.back_requested.connect(_on_back_requested)
	SafeArea.apply(_safe_area)
	get_tree().root.size_changed.connect(func() -> void: SafeArea.apply(_safe_area))
	var own := sim.ships_in_battle(0)
	if own.is_empty():
		push_error("Combat: no player ships in the battle context")
		return
	_set_flagship(own[0])
	_camera.global_position = _player.position
	_orders_button.visible = own.size() > 1
	if own.size() > 1:
		_enter_deploy(own)
	else:
		_set_phase(Phase.FIGHT)
	EventBus.battle_started.emit(context)


func _notification(what: int) -> void:
	# Combat pauses itself the moment the screen is lost (FR-CBT-9).
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_inside_tree() and not get_tree().paused and _phase != Phase.OVER:
			_open_pause()


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


# --- phases -----------------------------------------------------------------


func _set_phase(phase: Phase) -> void:
	_phase = phase
	var fighting := phase == Phase.FIGHT
	_joystick.visible = fighting and _scheme == Settings.ControlScheme.JOYSTICK
	_hint.visible = fighting and _scheme == Settings.ControlScheme.TAP
	_buttons.visible = fighting
	_command_panel.visible = phase == Phase.COMMAND
	_deploy_panel.visible = phase == Phase.DEPLOY
	_effects.show_orders = phase == Phase.COMMAND
	_camera.follow_target = _views.get(_player.id) if fighting and _player != null else null
	if phase != Phase.COMMAND:
		_select(null)


func _enter_deploy(own: Array[ShipState]) -> void:
	var group := ButtonGroup.new()
	for ship in own:
		var button := Button.new()
		button.text = ship.hull.display_name
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(150, 56)
		button.button_pressed = ship == _player
		button.pressed.connect(_set_flagship.bind(ship))
		_deploy_ships.add_child(button)
	_set_phase(Phase.DEPLOY)


func _start_fight() -> void:
	_set_phase(Phase.FIGHT)


func _enter_command() -> void:
	if _phase != Phase.FIGHT:
		return
	_pending_order = -1
	_set_phase(Phase.COMMAND)
	_refresh_command_panel()


func _leave_command() -> void:
	_pending_order = -1
	_set_phase(Phase.FIGHT)


# --- loop -------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	if _phase != Phase.FIGHT or _player == null:
		return
	_ensure_flagship()
	var started := Time.get_ticks_usec()
	for ship in sim.ships:
		if not ship.in_battle():
			continue
		if ship == _player and not ship.retreating:
			ship.command = _player_command()
		else:
			ship.command = ShipAI.decide(ship, sim)
	sim.step(delta)
	_sim_usec += Time.get_ticks_usec() - started
	_sim_steps += 1
	_peak_shots = maxi(_peak_shots, sim.projectiles.size())
	_effects.add_hits(sim.hits)
	var outcome := sim.outcome()
	if not outcome.is_empty():
		_finish(str(outcome.result))


func _process(delta: float) -> void:
	if _player == null:
		return
	_update_hud()
	_update_camera(delta)
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	# The first second after Engage holds load hitches; measure the battle, not the start-up.
	if _benchmark and _phase == Phase.FIGHT and sim.time > 1.0:
		_track_frame(delta)


func _update_camera(delta: float) -> void:
	var zoom := MAX_ZOOM
	if _phase == Phase.FIGHT:
		var target := _current_target()
		if target != null:
			var distance := _player.position.distance_to(target.position)
			zoom = clampf(360.0 / (distance * 0.5 + 220.0), MIN_ZOOM, MAX_ZOOM)
	else:
		var bounds := _battle_bounds()
		var view := get_viewport_rect().size
		zoom = clampf(minf(view.x / bounds.size.x, view.y / bounds.size.y), OVERVIEW_MIN_ZOOM, MAX_ZOOM)
		var centre := bounds.get_center()
		_camera.global_position = _camera.global_position.lerp(centre, minf(1.0, 4.0 * delta))
	var z: float = lerpf(_camera.zoom.x, zoom, minf(1.0, 3.0 * delta))
	_camera.zoom = Vector2(z, z)


## Rectangle around every ship still fighting, with a margin.
func _battle_bounds() -> Rect2:
	var bounds := Rect2(_player.position, Vector2.ZERO)
	for ship in sim.ships:
		if ship.in_battle():
			bounds = bounds.expand(ship.position)
	return bounds.grow(OVERVIEW_MARGIN)


## When the flagship is lost, command passes to the next ship still fighting.
func _ensure_flagship() -> void:
	if _player.in_battle():
		return
	for ship in sim.ships_in_battle(0):
		if not ship.retreating:
			_set_flagship(ship)
			_camera.follow_target = _views.get(ship.id)
			_show_toast("Flagship lost — you now command the %s" % ship.hull.display_name)
			return


func _set_flagship(ship: ShipState) -> void:
	if _player != null and _views.has(_player.id):
		_views[_player.id].flagship = false
	_player = ship
	_player.give_order(ShipState.Order.ENGAGE)
	_views[ship.id].flagship = true
	_target = null
	if _phase == Phase.DEPLOY or _phase == Phase.FIGHT:
		_camera.follow_target = _views.get(ship.id) if _phase == Phase.FIGHT else null


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
	if not _player.in_battle():
		_status.text = "%s — lost" % _player.hull.display_name
	elif _player.retreating:
		_status.text = "RETREATING"
	elif _player.is_overloaded():
		_status.text = "OVERLOADED"
	elif _player.venting:
		_status.text = "VENTING"
	else:
		_status.text = _player.hull.display_name
	if _vent_button.button_pressed and _player.flux <= 0.0:
		_vent_button.button_pressed = false
	_forces.text = "Fleet %d  ·  Enemy %d" % [sim.ships_in_battle(0).size(), sim.ships_in_battle(1).size()]
	var target := _current_target()
	_target_bars.visible = target != null
	if target != null:
		_target_name.text = target.hull.display_name
		_target_hull.value = target.hull_fraction() * 100.0
		_target_flux.value = target.flux_fraction() * 100.0


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_left = TOAST_SECONDS


# --- benchmark (NFR-1) ------------------------------------------------------


func _track_frame(delta: float) -> void:
	_frames += 1
	_frame_time += delta
	_worst_frame = maxf(_worst_frame, delta)
	_perf_window.append(delta)
	_perf_refresh -= delta
	if _perf_refresh > 0.0:
		return
	_perf_refresh = PERF_REFRESH_SECONDS
	var window_time := 0.0
	var window_worst := 0.0
	for d in _perf_window:
		window_time += d
		window_worst = maxf(window_worst, d)
	var fps := _perf_window.size() / maxf(window_time, 0.0001)
	_perf_window.clear()
	var sim_ms := _sim_usec / 1000.0 / maxf(_sim_steps, 1)
	_perf.text = "%d FPS  ·  worst %.1f ms  ·  sim %.2f ms/step  ·  %d ships  ·  %d shots" % [
		roundi(fps), window_worst * 1000.0, sim_ms, sim.ships_in_battle(0).size() + sim.ships_in_battle(1).size(),
		sim.projectiles.size()]


func _benchmark_report() -> Dictionary:
	return {
		"avg_fps": _frames / maxf(_frame_time, 0.0001),
		"worst_frame_ms": _worst_frame * 1000.0,
		"sim_ms_per_step": _sim_usec / 1000.0 / maxf(_sim_steps, 1),
		"peak_shots": _peak_shots,
	}


# --- input ------------------------------------------------------------------


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
				var world: Vector2 = _camera.screen_to_world(event.position)
				if _phase == Phase.COMMAND:
					_command_tap(world)
				elif _phase == Phase.FIGHT:
					_tap(world)
		get_viewport().set_input_as_handled()


func _tap(world: Vector2) -> void:
	var enemy := _ship_near(world, 1)
	if enemy != null:
		_target = enemy
		return
	if _scheme == Settings.ControlScheme.TAP:
		_move_target = world
		_has_move_target = true


## Nearest ship of a side to a world point, within tap reach (scaled by zoom).
func _ship_near(world: Vector2, side: int) -> ShipState:
	var best: ShipState = null
	var best_distance := TARGET_TAP_RADIUS / _camera.zoom.x
	for ship in sim.ships:
		if ship.side != side or not ship.in_battle():
			continue
		var d := ship.position.distance_to(world) - ship.radius
		if d < best_distance:
			best_distance = d
			best = ship
	return best


func _apply_scheme() -> void:
	_scheme = Settings.control_scheme
	_has_move_target = false
	_set_phase(_phase)


# --- command view (FR-CBT-5) --------------------------------------------------


func _command_tap(world: Vector2) -> void:
	if _pending_order == ShipState.Order.ENGAGE and _selected != null:
		var enemy := _ship_near(world, 1)
		if enemy != null:
			_selected.give_order(ShipState.Order.ENGAGE, enemy.id)
			_selected.retreating = false
			_pending_order = -1
		_refresh_command_panel()
		return
	if _pending_order == ShipState.Order.DEFEND and _selected != null:
		_selected.give_order(ShipState.Order.DEFEND, -1, world)
		_selected.retreating = false
		_pending_order = -1
		_refresh_command_panel()
		return
	var ally := _ship_near(world, 0)
	if ally == _player:
		_show_toast("That is your flagship — you fly it yourself")
		return
	_select(ally)
	_refresh_command_panel()


func _select(ship: ShipState) -> void:
	if _selected != null and _views.has(_selected.id):
		_views[_selected.id].selected = false
	_selected = ship
	if ship != null:
		_views[ship.id].selected = true


func _arm_order(order: ShipState.Order) -> void:
	if _selected == null:
		return
	_pending_order = order
	_refresh_command_panel()


func _order_selected_retreat() -> void:
	if _selected == null:
		return
	_selected.give_order(ShipState.Order.RETREAT)
	_pending_order = -1
	_refresh_command_panel()


func _full_retreat() -> void:
	for ship in sim.ships_in_battle(0):
		ship.give_order(ShipState.Order.RETREAT)
	_show_toast("Full retreat — every ship is heading for the left edge")
	if _phase == Phase.COMMAND:
		_leave_command()


func _refresh_command_panel() -> void:
	var has_selection := _selected != null and _selected.in_battle()
	_order_engage.disabled = not has_selection
	_order_defend.disabled = not has_selection
	_order_retreat.disabled = not has_selection
	if not has_selection:
		_command_hint.text = "Tap one of your escorts (blue) to give it an order"
	elif _pending_order == ShipState.Order.ENGAGE:
		_command_hint.text = "%s: tap the enemy to engage" % _selected.hull.display_name
	elif _pending_order == ShipState.Order.DEFEND:
		_command_hint.text = "%s: tap the point to defend" % _selected.hull.display_name
	else:
		_command_hint.text = "%s selected — choose an order" % _selected.hull.display_name


# --- overlays and transitions -----------------------------------------------


func _on_back_requested() -> void:
	if _phase == Phase.OVER:
		return
	if _settings_menu.visible:
		_settings_menu.close()
	elif _pause_menu.visible:
		_pause_menu.close()
	elif _phase == Phase.COMMAND:
		if _pending_order != -1:
			_pending_order = -1
			_refresh_command_panel()
		else:
			_leave_command()
	else:
		_open_pause()


func _open_pause() -> void:
	_pause_menu.open()


func _retreat_from_pause() -> void:
	_pause_menu.close()
	if _phase == Phase.DEPLOY:
		# Nobody has moved yet: withdrawing is immediate.
		for ship in sim.ships_in_battle(0):
			ship.escaped = true
		_finish("retreat")
		return
	_full_retreat()


func _finish(outcome: String) -> void:
	if _phase == Phase.OVER:
		return
	_set_phase(Phase.OVER)
	var ships: Array = []
	for ship in sim.ships:
		ships.append(ship.to_dict())
	_result = {
		"outcome": outcome,
		"time": sim.time,
		"ships": ships,
		"flagship_id": _player.id,
		"return_to": GameState.battle.get("return_to", "main_menu"),
	}
	if _benchmark:
		_result["benchmark"] = _benchmark_report()
	_result_screen.show_result(_result)


func _leave() -> void:
	get_tree().paused = false
	EventBus.battle_ended.emit(_result)
	SceneRouter.go(str(_result.return_to))
