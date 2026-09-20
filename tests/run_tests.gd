extends SceneTree
## Unit test runner:
##   godot --headless --path . -s res://tests/run_tests.gd
## Loads every tests/unit/test_*.gd, runs its test_* methods and exits with 1
## on any failure. Tests target the model layer (no scenes, no autoloads).


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests/unit")
	if dir == null:
		printerr("tests/unit not found")
		quit(1)
		return
	var files := Array(dir.get_files())
	files.sort()
	for file: String in files:
		var name := file.trim_suffix(".remap")
		if not (name.begins_with("test_") and name.ends_with(".gd")):
			continue
		var script: GDScript = load("res://tests/unit/" + name)
		var case: TestCase = script.new()
		var count := 0
		for method: Dictionary in script.get_script_method_list():
			if not method.name.begins_with("test_"):
				continue
			case.begin(method.name)
			case.call(method.name)
			count += 1
		total += count
		failed += case.failures.size()
		for failure: String in case.failures:
			printerr("  FAIL %s :: %s" % [name, failure])
		print("%-32s %2d test(s), %d failure(s)" % [name, count, case.failures.size()])
	print("%d tests, %d failures" % [total, failed])
	quit(1 if failed > 0 else 0)
