class_name SkirmishData
extends Resource
## A stand-alone battle offered on the title screen (play-testing and the
## performance benchmark). One .tres per scenario under res://data/skirmishes/.
## `player` and `enemy` use the BattleBuilder spec shape:
## {"hull": id, "fit": {slot_id: weapon_id}, "count": n}.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Menu order, lowest first.
@export var order: int = 0
@export var player: Array = []
@export var enemy: Array = []
## Arena width and height in world units.
@export var arena: Vector2 = Vector2(2400, 1600)
## Shows the frame-time overlay and reports frame statistics at the end (NFR-1).
@export var benchmark: bool = false


## The GameState.battle context for this scenario.
func to_context(return_to: String) -> Dictionary:
	return {
		"return_to": return_to,
		"player": player.duplicate(true),
		"enemy": enemy.duplicate(true),
		"arena": [arena.x, arena.y],
		"benchmark": benchmark,
		"title": display_name,
	}
