extends Control
## End-of-battle overlay: outcome, what happened to each side, the flagship,
## benchmark figures when the battle was a benchmark, and Continue.

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
	_summary.text = summary_text(result)
	show()
	get_tree().paused = true
	_continue.grab_focus()


## Plain-text summary of a battle result.
static func summary_text(result: Dictionary) -> String:
	var tally := [{"destroyed": 0, "escaped": 0, "total": 0}, {"destroyed": 0, "escaped": 0, "total": 0}]
	var flagship := {}
	for ship: Dictionary in result.get("ships", []):
		var side: Dictionary = tally[int(ship.side)]
		side.total += 1
		if not ship.alive:
			side.destroyed += 1
		elif ship.escaped:
			side.escaped += 1
		if int(ship.id) == int(result.get("flagship_id", -1)):
			flagship = ship
	var lines := PackedStringArray()
	lines.append("Enemy: %d destroyed, %d fled, of %d" % [tally[1].destroyed, tally[1].escaped, tally[1].total])
	lines.append("Your fleet: %d lost, %d withdrew, of %d" % [tally[0].destroyed, tally[0].escaped, tally[0].total])
	if not flagship.is_empty():
		lines.append("Flagship %s: hull %d%%" % [flagship.get("name", ""), roundi(float(flagship.hull_fraction) * 100.0)])
	lines.append("Battle time %d s" % int(result.get("time", 0.0)))
	var bench: Dictionary = result.get("benchmark", {})
	if not bench.is_empty():
		lines.append("Benchmark: %.0f FPS average, worst frame %.1f ms, sim %.2f ms/step, peak %d shots" % [
			bench.avg_fps, bench.worst_frame_ms, bench.sim_ms_per_step, bench.peak_shots])
	return "\n".join(lines)
