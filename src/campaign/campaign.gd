extends Node2D
## Campaign mode root: the star system view the player flies around in.
## Milestone M0 placeholder; the system scene, player fleet and travel
## arrive in M1 (see docs/ROADMAP.md).

@onready var _status: Label = $HUD/Margin/TopBar/Status
@onready var _back: Button = $HUD/Margin/TopBar/Back


func _ready() -> void:
	_refresh_status()
	_back.pressed.connect(_on_back)
	EventBus.day_passed.connect(func(_day: int) -> void: _refresh_status())


func _refresh_status() -> void:
	_status.text = "Day %d - %d cr" % [GameState.day, GameState.credits]


func _on_back() -> void:
	SaveService.save_game()
	SceneRouter.go("main_menu")
