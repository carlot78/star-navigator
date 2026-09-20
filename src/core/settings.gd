extends Node
## User preferences (audio, controls, UI scale). Persisted in
## user://settings.cfg, independent of any save game.

enum ControlScheme { JOYSTICK, TAP }

const PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var control_scheme: ControlScheme = ControlScheme.JOYSTICK
var ui_scale: float = 1.0
var haptics: bool = true


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	control_scheme = cfg.get_value("controls", "scheme", control_scheme)
	haptics = cfg.get_value("controls", "haptics", haptics)
	ui_scale = cfg.get_value("ui", "scale", ui_scale)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("controls", "scheme", control_scheme)
	cfg.set_value("controls", "haptics", haptics)
	cfg.set_value("ui", "scale", ui_scale)
	var err := cfg.save(PATH)
	if err != OK:
		push_error("Settings: could not save %s (%d)" % [PATH, err])


## Pushes the current values into the engine (audio bus, UI scale).
func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(master_volume, 0.0001, 1.0)))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)
	get_tree().root.content_scale_factor = ui_scale
