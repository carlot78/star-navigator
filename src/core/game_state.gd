extends Node
## The single in-memory model of the current playthrough. Everything a save
## file contains lives here or in objects owned by here. Scenes read it and
## change it through domain services; they never keep a private copy.
##
## Bump SAVE_VERSION whenever to_dict() changes shape and add a migration
## step in SaveService._migrate().

const SAVE_VERSION := 1

var player_name: String = ""
var credits: int = 0
var day: int = 1
var seed: int = 0
## Ships in the player fleet. Each entry is a Dictionary for now; it becomes a
## ShipInstance model in milestone M5 (see docs/ROADMAP.md).
var fleet: Array = []
## Where the player fleet is: { "system": id, "position": [x, y] }.
var location: Dictionary = {}
## The battle about to be fought or in progress (see combat.gd _build for the
## shape). Transient: set by whoever starts a battle, never saved.
var battle: Dictionary = {}


func new_game(p_seed: int = 0) -> void:
	seed = p_seed if p_seed != 0 else randi()
	player_name = "Captain"
	credits = 10000
	day = 1
	fleet = [{"hull": "kestrel"}]
	location = {"system": "home", "position": [0.0, 320.0], "heading": 0.0}
	EventBus.game_started.emit(true)


func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"player_name": player_name,
		"credits": credits,
		"day": day,
		"seed": seed,
		"fleet": fleet.duplicate(true),
		"location": location.duplicate(true),
	}


func from_dict(d: Dictionary) -> void:
	player_name = d.get("player_name", "Captain")
	credits = int(d.get("credits", 0))
	day = int(d.get("day", 1))
	seed = int(d.get("seed", 0))
	fleet = d.get("fleet", [])
	location = d.get("location", {})


## Hull id of the ship the player pilots (the first in the fleet).
func flagship_hull_id() -> String:
	if fleet.is_empty():
		return "kestrel"
	return str(fleet[0].get("hull", "kestrel"))


## The fleet position inside the current system.
func location_position() -> Vector2:
	var p: Array = location.get("position", [0.0, 0.0])
	return Vector2(float(p[0]), float(p[1])) if p.size() >= 2 else Vector2.ZERO
