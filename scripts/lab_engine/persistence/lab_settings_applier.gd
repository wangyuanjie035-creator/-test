class_name LabSettingsApplier
extends RefCounted

static func volume_to_db(linear_volume: float) -> float:
	return linear_to_db(maxf(clampf(linear_volume, 0.0, 1.0), 0.001))

static func apply(settings: Dictionary) -> void:
	var volume := clampf(float(settings.get("master_volume", 0.8)), 0.0, 1.0)
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, volume <= 0.001)
		AudioServer.set_bus_volume_db(master_bus, volume_to_db(volume))
	var mode := String(settings.get("window_mode", "windowed"))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if mode == "fullscreen" else DisplayServer.WINDOW_MODE_WINDOWED)
