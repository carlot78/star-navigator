extends Control
## Lists the SkirmishData scenarios from data/skirmishes and emits the one
## the player picks. Each entry is a button with the name and description.

signal chosen(skirmish: SkirmishData)
signal closed

@onready var _list: VBoxContainer = $Center/Panel/VBox/List
@onready var _back: Button = $Center/Panel/VBox/Back


func _ready() -> void:
	_back.pressed.connect(close)
	var skirmishes: Array = DataRegistry.get_all("skirmishes")
	skirmishes.sort_custom(func(a: SkirmishData, b: SkirmishData) -> bool: return a.order < b.order)
	for skirmish: SkirmishData in skirmishes:
		var button := Button.new()
		button.text = "%s\n%s" % [skirmish.display_name, skirmish.description]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 76)
		button.pressed.connect(func() -> void: chosen.emit(skirmish))
		_list.add_child(button)


func open() -> void:
	show()
	if _list.get_child_count() > 0:
		(_list.get_child(0) as Button).grab_focus()


func close() -> void:
	hide()
	closed.emit()
