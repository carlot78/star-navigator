extends Control
## Pause overlay. Opening it pauses the scene tree; the overlay itself lives
## under a CanvasLayer with process_mode ALWAYS so its buttons keep working.

signal resumed
signal settings_requested
signal quit_requested

@onready var _resume: Button = $Center/VBox/Resume
@onready var _settings: Button = $Center/VBox/Settings
@onready var _quit: Button = $Center/VBox/Quit


func _ready() -> void:
	_resume.pressed.connect(func() -> void: resumed.emit())
	_settings.pressed.connect(func() -> void: settings_requested.emit())
	_quit.pressed.connect(func() -> void: quit_requested.emit())


func open() -> void:
	show()
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false
