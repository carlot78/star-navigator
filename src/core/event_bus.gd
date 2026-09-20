extends Node
## Global signal hub. Domains talk to each other only through these signals,
## never by reaching into each other's scenes. Signal names are past-tense
## events ("battle_ended"), not commands.

# Session
signal game_started(new_game: bool)
signal game_saved(slot: String)
signal game_loaded(slot: String)
signal scene_changed(scene_path: String)
## Android back button or Escape: overlays close, then the pause menu opens.
signal back_requested

# Campaign
signal day_passed(day: int)
signal fleet_arrived(location: Dictionary)
signal encounter_triggered(context: Dictionary)

# Combat
signal battle_started(context: Dictionary)
signal battle_ended(result: Dictionary)
