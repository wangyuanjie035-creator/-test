class_name LabTestCase
extends RefCounted

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func check_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected=%s, actual=%s)" % [message, expected, actual])

