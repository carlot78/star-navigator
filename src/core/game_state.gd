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


func new_game(p_seed: int = 0) -> void:
	seed = p_seed if p_seed != 0 else randi()
	player_name = "Captain"
	credits = 10000
	day = 1
	fleet = []
	location = {}
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
