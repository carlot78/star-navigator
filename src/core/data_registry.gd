extends Node
## Loads every content Resource under res://data/ at startup and exposes it by
## id. Content is data, not code: adding a hull or a weapon means adding a
## .tres file to the right folder, never touching a script.

const ROOTS := {
	"hulls": "res://data/hulls",
	"weapons": "res://data/weapons",
	"factions": "res://data/factions",
}

var _tables: Dictionary = {}


func _ready() -> void:
	for table: String in ROOTS:
		_tables[table] = _load_dir(ROOTS[table])
		print("DataRegistry: loaded %d %s" % [_tables[table].size(), table])


## Returns the Resource with the given id in a table, or null.
func get_entry(table: String, id: String) -> Resource:
	return _tables.get(table, {}).get(id)


## Returns every Resource of a table, in load order.
func get_all(table: String) -> Array:
	return _tables.get(table, {}).values()


func _load_dir(path: String) -> Dictionary:
	var out := {}
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("DataRegistry: missing folder %s" % path)
		return out
	for file: String in dir.get_files():
		# Exported builds convert .tres to binary and leave a ".tres.remap" stub;
		# loading the original path still works through the remap.
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var res: Resource = load(path.path_join(name))
		if res == null or not ("id" in res) or res.id == "":
			push_warning("DataRegistry: %s has no id, skipped" % name)
			continue
		if out.has(res.id):
			push_warning("DataRegistry: duplicate id '%s' in %s" % [res.id, path])
		out[res.id] = res
	return out
