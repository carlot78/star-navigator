extends Control
## Title screen. Starts a fresh playthrough, resumes the autosave, or opens
## the settings overlay.

@onready var _new_game: Button = $Center/VBox/NewGame
@onready var _continue: Button = $Center/VBox/Continue
@onready var _settings: Button = $Center/VBox/Settings
@onready var _version: Label = $Center/VBox/Version
@onready var _settings_menu: Control = $SettingsMenu


func _ready() -> void:
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "dev")
	_continue.disabled = not SaveService.has_slot()
	_new_game.pressed.connect(_on_new_game)
	_continue.pressed.connect(_on_continue)
	_settings.pressed.connect(_settings_menu.open)
	EventBus.back_requested.connect(_on_back_requested)


func _on_new_game() -> void:
	GameState.new_game()
	SaveService.save_game()
	SceneRouter.go("campaign")


func _on_continue() -> void:
	if SaveService.load_game() == OK:
		SceneRouter.go("campaign")


func _on_back_requested() -> void:
	if _settings_menu.visible:
		_settings_menu.close()
	elif OS.has_feature("mobile"):
		# Back on the title screen leaves the app, as Android users expect (FR-UX-6).
		get_tree().quit()
