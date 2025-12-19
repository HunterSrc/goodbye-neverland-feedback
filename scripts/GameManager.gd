extends Node

@export var debug_enabled: bool = false
@export var show_collision_debug: bool = false

# Hitstop
@export var hitstop_enabled: bool = true
@export var hitstop_time: float = 0.05       # 0.04–0.06
@export var hitstop_timescale: float = 0.05  # non usare 0.0

# Screenshake
@export var screenshake_enabled: bool = true
@export var screenshake_duration: float = 0.08
@export var screenshake_strength: float = 6.0

var current_level_path: String = ""
var run_time_seconds: float = 0.0
var lore_flags: Dictionary = {}

var _hitstop_active: bool = false


func d(msg: String) -> void:
	if debug_enabled:
		print("[GM] " + msg)


func _process(delta: float) -> void:
	run_time_seconds += delta


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func set_lore_flag(key: String, value: bool = true) -> void:
	lore_flags[key] = value
	d("Lore flag set: %s = %s" % [key, str(value)])


func has_lore_flag(key: String) -> bool:
	return lore_flags.has(key) and bool(lore_flags[key])


func load_level(level_scene: PackedScene) -> void:
	if level_scene == null:
		push_error("[GM] load_level: scena null")
		return

	var main := get_tree().current_scene
	if main and main.has_method("load_level"):
		main.load_level(level_scene)
		current_level_path = level_scene.resource_path
		d("Requested load_level via Main: %s" % current_level_path)
	else:
		var err := get_tree().change_scene_to_packed(level_scene)
		if err != OK:
			push_error("[GM] change_scene_to_packed failed: %s" % str(err))
		else:
			current_level_path = level_scene.resource_path
			d("Loaded level via SceneTree: %s" % current_level_path)


func hitstop(time_sec: float = -1.0, timescale: float = -1.0) -> void:
	if not hitstop_enabled:
		return
	if _hitstop_active:
		return

	var t := hitstop_time if time_sec < 0.0 else time_sec
	var s := hitstop_timescale if timescale < 0.0 else timescale

	_hitstop_active = true
	var old := Engine.time_scale
	Engine.time_scale = s

	# Timer che ignora time_scale (IMPORTANT)
	await get_tree().create_timer(t, false, false, true).timeout

	Engine.time_scale = old
	_hitstop_active = false


func screenshake(duration: float = -1.0, strength: float = -1.0) -> void:
	if not screenshake_enabled:
		return

	var d0 := screenshake_duration if duration < 0.0 else duration
	var s0 := screenshake_strength if strength < 0.0 else strength

	var main := get_tree().current_scene
	if main and main.has_method("shake"):
		main.shake(d0, s0)
