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

# Screen flash (visual feedback)
@export var flash_on_hit: bool = true
@export var flash_on_damage: bool = true
@export var flash_duration_hit: float = 0.08
@export var flash_duration_damage: float = 0.12
@export var flash_color_hit: Color = Color(1, 1, 1, 0.50)
@export var flash_color_damage: Color = Color(1, 0.35, 0.35, 0.55)

# Audio
@export var beat_stream: AudioStream
@export var hit_on_beat_stream: AudioStream
@export var miss_stream: AudioStream
@export var damage_stream: AudioStream
@export var sfx_volume_db: float = -6.0
@export var fade_on_level_load: bool = true
@export var show_title_on_level_load: bool = true
@export var fade_on_reload: bool = true
@export var show_title_on_reload: bool = false

var current_level_path: String = ""
var run_time_seconds: float = 0.0
var lore_flags: Dictionary = {}
var noise_total: int = 0
var noise_destroyed: int = 0

var _hitstop_active: bool = false
var _player_beat: AudioStreamPlayer
var _player_hit: AudioStreamPlayer
var _player_miss: AudioStreamPlayer
var _player_damage: AudioStreamPlayer


func d(msg: String) -> void:
	if debug_enabled:
		print("[GM] " + msg)


func _process(delta: float) -> void:
	run_time_seconds += delta


func _ready() -> void:
	# Audio players
	_player_beat = _make_player(beat_stream)
	_player_hit = _make_player(hit_on_beat_stream)
	_player_miss = _make_player(miss_stream)
	_player_damage = _make_player(damage_stream)
	


func _make_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = sfx_volume_db
	add_child(p)
	return p


func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func set_lore_flag(key: String, value: bool = true) -> void:
	lore_flags[key] = value
	d("Lore flag set: %s = %s" % [key, str(value)])


func has_lore_flag(key: String) -> bool:
	return lore_flags.has(key) and bool(lore_flags[key])


func load_level(level_scene: PackedScene, use_fade: bool = fade_on_level_load, show_title: bool = show_title_on_level_load) -> void:
	if level_scene == null:
		push_error("[GM] load_level: scena null")
		return

	_force_time_scale_normal()
	_reset_noise_counters()

	var main := get_tree().current_scene
	if main and main.has_method("load_level"):
		main.load_level(level_scene, use_fade, show_title)
		current_level_path = level_scene.resource_path
		d("Requested load_level via Main: %s (fade=%s title=%s)" % [current_level_path, str(use_fade), str(show_title)])
	else:
		var err := get_tree().change_scene_to_packed(level_scene)  # fallback senza fade/title
		if err != OK:
			push_error("[GM] change_scene_to_packed failed: %s" % str(err))
		else:
			current_level_path = level_scene.resource_path
			d("Loaded level via SceneTree: %s" % current_level_path)


func reload_level(use_fade: bool = fade_on_reload, show_title: bool = show_title_on_reload) -> void:
	"""Ricarica il livello corrente. Wrapper per Main.reload_current_level()."""
	# Reset time_scale immediatamente (importante se la morte avviene durante hitstop)
	_force_time_scale_normal()
	_reset_noise_counters()

	var main := get_tree().current_scene
	if main and main.has_method("reload_current_level"):
		await main.reload_current_level(use_fade, show_title)
		d("Reloaded level via Main: %s" % current_level_path)
	else:
		push_error("[GM] reload_level: Main non ha metodo reload_current_level")


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


func flash_hit() -> void:
	if not flash_on_hit:
		return
	_flash(flash_color_hit, flash_duration_hit)


func flash_damage() -> void:
	if not flash_on_damage:
		return
	_flash(flash_color_damage, flash_duration_damage)


func _flash(c: Color, duration: float) -> void:
	var main := get_tree().current_scene
	if main and main.has_method("flash"):
		main.flash(c, duration)


# Audio helpers (placeholder per quando avremo file audio)
func play_beat_tick() -> void:
	if _player_beat and _player_beat.stream:
		_player_beat.play()


func play_hit_on_beat() -> void:
	if _player_hit and _player_hit.stream:
		_player_hit.play()


func play_miss() -> void:
	if _player_miss and _player_miss.stream:
		_player_miss.play()


func play_damage() -> void:
	if _player_damage and _player_damage.stream:
		_player_damage.play()


# NoiseBlock tracking
func _reset_noise_counters() -> void:
	noise_total = 0
	noise_destroyed = 0


func register_noise_block(_node: Node) -> void:
	noise_total += 1
	d("Noise register: %d/%d" % [noise_destroyed, noise_total])


func noise_block_destroyed() -> void:
	noise_destroyed = clamp(noise_destroyed + 1, 0, noise_total)
	d("Noise destroyed: %d/%d" % [noise_destroyed, noise_total])


func get_noise_progress() -> Dictionary:
	return {
		"destroyed": noise_destroyed,
		"total": noise_total
	}


func scan_noise_blocks() -> void:
	noise_total = get_tree().get_nodes_in_group("noise_block").size()
	noise_destroyed = 0
	print("[GM] Noise scan: %d total" % noise_total)


func scan_noise_blocks_deferred() -> void:
	call_deferred("scan_noise_blocks")


func all_noise_cleared() -> bool:
	return noise_total > 0 and noise_destroyed >= noise_total


func _force_time_scale_normal() -> void:
	Engine.time_scale = 1.0
	_hitstop_active = false
