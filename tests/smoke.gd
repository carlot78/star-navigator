extends SceneTree
## Headless smoke test, run by CI and locally with
##   godot --headless --path . -s res://tests/smoke.gd
## It exercises the model layer directly and boots every scene once.
## Unit tests live in tests/unit (run_tests.gd); this stays as the boot check.

var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_ship_mover()
	_test_all_scenes_load()
	await _test_campaign_boot_and_tap()
	await _test_combat_boot()
	await _test_save_round_trip()
	if _failures == 0:
		print("SMOKE OK")
		quit(0)
	else:
		printerr("SMOKE FAILED: %d check(s)" % _failures)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("  FAIL: " + message)


# --- model ----------------------------------------------------------------


func _test_ship_mover() -> void:
	var mover := ShipMover.new()
	mover.max_speed = 140.0
	mover.acceleration = 100.0
	mover.turn_rate = 80.0
	mover.set_target(Vector2(500.0, 0.0))
	var peak := 0.0
	for _i in 60 * 12:
		mover.step(1.0 / 60.0)
		peak = maxf(peak, mover.velocity.length())
	_check(not mover.has_target, "mover reaches its target within 12 s")
	_check(mover.position.distance_to(Vector2(500.0, 0.0)) < 1.0, "mover stops on the target")
	_check(peak <= 140.0 + 0.01, "mover never exceeds max speed (peak %.1f)" % peak)
	_check(absf(mover.heading) < 0.01, "mover faces +X after flying along +X")


# --- scenes ---------------------------------------------------------------


func _test_all_scenes_load() -> void:
	for path: String in _find_files("res://src", ".tscn"):
		var scene: PackedScene = load(path)
		_check(scene != null, "loads " + path)
		if scene != null:
			var node := scene.instantiate()
			_check(node != null, "instantiates " + path)
			if node != null:
				node.free()
	var theme: Theme = load("res://src/ui/theme/theme.tres")
	_check(theme != null, "loads the theme")


func _find_files(dir_path: String, suffix: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub: String in dir.get_directories():
		out.append_array(_find_files(dir_path.path_join(sub), suffix))
	for file: String in dir.get_files():
		var name := file.trim_suffix(".remap")
		if name.ends_with(suffix):
			out.append(dir_path.path_join(name))
	return out


func _test_campaign_boot_and_tap() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.new_game(42)
	var campaign: Node2D = (load("res://src/campaign/campaign.tscn") as PackedScene).instantiate()
	root.add_child(campaign)
	await process_frame
	await process_frame
	var ship: Node2D = campaign.get_node("PlayerShip")
	_check(ship.position.is_equal_approx(Vector2(0.0, 320.0)), "ship starts at the saved location")
	# Simulate a tap far from the ship: down, then up at the same spot.
	var screen := Vector2(100.0, 100.0)
	_send_touch(screen, true)
	await process_frame
	_send_touch(screen, false)
	await process_frame
	_check(ship.mover.has_target, "a tap sets a course")
	for _i in 30:
		await physics_frame
	_check(ship.position.distance_to(Vector2(0.0, 320.0)) > 5.0, "the ship flies toward the tapped point")
	campaign.get_node("HUD/PauseMenu").open()
	_check(paused, "pause menu pauses the tree")
	campaign.get_node("HUD/PauseMenu").close()
	_check(not paused, "closing the pause menu resumes")
	ship.write_state()
	campaign.free()


func _send_touch(screen: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = screen
	event.pressed = pressed
	Input.parse_input_event(event)


# --- persistence ----------------------------------------------------------


func _test_save_round_trip() -> void:
	var game_state: Node = root.get_node("GameState")
	var save_service: Node = root.get_node("SaveService")
	var registry: Node = root.get_node("DataRegistry")
	game_state.credits = 12345
	game_state.day = 7
	var saved_position: Vector2 = game_state.location_position()
	_check(save_service.save_game("smoke") == OK, "save_game writes")
	game_state.credits = 0
	game_state.day = 1
	game_state.location = {}
	_check(save_service.load_game("smoke") == OK, "load_game reads")
	_check(game_state.credits == 12345 and game_state.day == 7 and game_state.seed == 42, "loaded values match")
	_check(game_state.location_position().is_equal_approx(saved_position), "ship position survives a save")
	_check(game_state.flagship_hull_id() == "kestrel", "flagship hull survives a save")
	var hull: HullData = registry.get_entry("hulls", "kestrel")
	_check(hull != null and hull.weapon_slots.size() == 2, "kestrel hull loads with its slots")
	DirAccess.remove_absolute(save_service.slot_path("smoke"))
	await process_frame


# --- combat ---------------------------------------------------------------


func _test_combat_boot() -> void:
	var game_state: Node = root.get_node("GameState")
	game_state.battle = {
		"return_to": "main_menu",
		"player": [{"hull": "kestrel", "fit": {"nose": "light_autocannon", "turret": "shard_flak"}}],
		"enemy": [{"hull": "harrier", "fit": {"left": "pulse_laser", "right": "pulse_laser"}}],
	}
	var combat: Node2D = (load("res://src/combat/combat.tscn") as PackedScene).instantiate()
	root.add_child(combat)
	await process_frame
	var sim: CombatSim = combat.sim
	_check(sim.ships.size() == 2, "combat spawns both ships")
	_check(combat.get_node("Ships").get_child_count() == 2, "one view per ship")
	var fire: Button = combat.get_node("HUD/SafeArea/Root/Buttons/Fire")
	var shield: Button = combat.get_node("HUD/SafeArea/Root/Buttons/Shield")
	fire.button_pressed = true
	shield.button_pressed = true
	for _i in 60 * 4:
		await physics_frame
	_check(sim.time > 3.0, "the sim advances with physics frames")
	_check(sim.ships[0].shield_up, "the shield toggle raises the player shield")
	var enemy := sim.ships[1]
	_check(enemy.hull_points < enemy.hull.hull_points or enemy.flux > 0.0, "the player's guns reach the enemy")
	_check(sim.ships[0].command.face != Vector2.ZERO, "the player ship faces its target")
	combat.get_node("HUD/PauseMenu").open()
	_check(paused, "combat pauses")
	combat.get_node("HUD/PauseMenu").close()
	combat.free()
	game_state.battle = {}
