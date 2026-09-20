class_name TestCase
extends RefCounted
## Base class for unit tests under tests/unit/. A test file extends this and
## defines methods named test_*; run_tests.gd calls each one and collects
## failures. Assertions record failures instead of stopping, so one run
## reports everything that is wrong.

var failures: Array[String] = []
var _current: String = ""


func begin(test_name: String) -> void:
	_current = test_name


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("expected false", message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_fail("expected %s, got %s" % [expected, actual], message)


func assert_almost(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		_fail("expected %.4f ± %.4f, got %.4f" % [expected, tolerance, actual], message)


func assert_gt(actual: float, threshold: float, message: String = "") -> void:
	if not actual > threshold:
		_fail("expected > %s, got %s" % [threshold, actual], message)


func assert_lt(actual: float, threshold: float, message: String = "") -> void:
	if not actual < threshold:
		_fail("expected < %s, got %s" % [threshold, actual], message)


func _fail(detail: String, message: String) -> void:
	var text := "%s: %s" % [_current, detail]
	if message != "":
		text += " (%s)" % message
	failures.append(text)
