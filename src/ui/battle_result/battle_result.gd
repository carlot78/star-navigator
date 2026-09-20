extends Control
## End-of-battle overlay: outcome, a short tally, and Continue.

signal continued

const TITLES := {"victory": "Victory", "defeat": "Defeat", "retreat": "Retreat"}
const COLORS := {
	"victory": Color(0.55, 0.9, 0.6),
	"defeat": Color(1.0, 0.5, 0.45),
	"retreat": Color(0.85, 0.85, 0.6),
}

@onready var _title: Label = $Center/Panel/VBox/Title
@onready var _summary: Label = $Center/Panel/VBox/Summary
@onready var _continue: Button = $Center/Panel/VBox/Continue


func _ready() -> void:
	_continue.pressed.connect(func() -> void: continued.emit())


func show_result(result: Dictionary) -> void:
	var outcome := str(result.get("outcome", "retreat"))
	_title.text = TITLES.get(outcome, outcome)
	_title.add_theme_color_override("font_color", COLORS.get(outcome, Color.WHITE))
	var destroyed := 0
	var lost := 0
	var player_hull := 0.0
	for ship: Dictionary in result.get("ships", []):
		if ship.side == 0:
			player_hull = float(ship.hull_fraction)
			if not ship.alive:
				lost += 1
		elif not ship.alive:
			destroyed += 1
	_summary.text = "%d enemy destroyed, %d lost\nFlagship hull %d%%  ·  %d s" % [
		destroyed, lost, int(round(player_hull * 100.0)), int(result.get("time", 0.0))]
	show()
	get_tree().paused = true
	_continue.grab_focus()
