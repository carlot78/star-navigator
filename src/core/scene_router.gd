extends Node
## Switches between top-level scenes by name so the rest of the code never
## hard-codes scene paths. One scene per game mode (menu, campaign, combat).

const SCENES := {
	"main_menu": "res://src/ui/main_menu/main_menu.tscn",
	"campaign": "res://src/campaign/campaign.tscn",
}


## Goes to a registered scene name, or to a raw res:// path.
func go(key: String) -> void:
	var path: String = SCENES.get(key, key)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: cannot load %s (%d)" % [path, err])
		return
	EventBus.scene_changed.emit(path)


func _ready() -> void:
	# Back must work while the tree is paused (pause menu open).
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		EventBus.back_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.back_requested.emit()
