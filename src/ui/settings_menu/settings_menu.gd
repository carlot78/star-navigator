extends Control
## Settings overlay (FR-UX-5). Every control is bound to the Settings
## autoload: changes apply immediately and are written to disk on Back.

signal closed

@onready var _master: HSlider = $Center/Panel/VBox/Grid/Master
@onready var _music: HSlider = $Center/Panel/VBox/Grid/Music
@onready var _sfx: HSlider = $Center/Panel/VBox/Grid/Sfx
@onready var _scheme: OptionButton = $Center/Panel/VBox/Grid/Scheme
@onready var _scale: HSlider = $Center/Panel/VBox/Grid/Scale
@onready var _haptics: CheckButton = $Center/Panel/VBox/Grid/Haptics
@onready var _back: Button = $Center/Panel/VBox/Back


func _ready() -> void:
	_scheme.add_item("Virtual joystick", Settings.ControlScheme.JOYSTICK)
	_scheme.add_item("Tap to move & target", Settings.ControlScheme.TAP)
	_master.value_changed.connect(_apply_from_controls.unbind(1))
	_music.value_changed.connect(_apply_from_controls.unbind(1))
	_sfx.value_changed.connect(_apply_from_controls.unbind(1))
	_scheme.item_selected.connect(_apply_from_controls.unbind(1))
	_scale.value_changed.connect(_apply_from_controls.unbind(1))
	_haptics.toggled.connect(_apply_from_controls.unbind(1))
	_back.pressed.connect(close)


func open() -> void:
	_master.set_value_no_signal(Settings.master_volume)
	_music.set_value_no_signal(Settings.music_volume)
	_sfx.set_value_no_signal(Settings.sfx_volume)
	_scheme.select(_scheme.get_item_index(Settings.control_scheme))
	_scale.set_value_no_signal(Settings.ui_scale)
	_haptics.set_pressed_no_signal(Settings.haptics)
	show()
	_back.grab_focus()


func close() -> void:
	Settings.save_settings()
	hide()
	closed.emit()


func _apply_from_controls() -> void:
	Settings.master_volume = _master.value
	Settings.music_volume = _music.value
	Settings.sfx_volume = _sfx.value
	Settings.control_scheme = _scheme.get_selected_id() as Settings.ControlScheme
	Settings.ui_scale = _scale.value
	Settings.haptics = _haptics.button_pressed
	Settings.apply()
