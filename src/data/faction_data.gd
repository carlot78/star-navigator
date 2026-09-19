class_name FactionData
extends Resource
## A political entity that owns markets, fields fleets and holds an opinion
## of the player. One .tres per faction under res://data/factions/.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color.WHITE
## Hull ids this faction builds its fleets from.
@export var hull_pool: Array[String] = []
## Reputation with the player at the start of a new game, -100..100.
@export var starting_reputation: int = 0
