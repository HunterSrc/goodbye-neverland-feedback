extends Node

@export var first_level: PackedScene
@export var debug_enabled: bool = false

@export var fade_time: float = 0.30

@export var show_title_card: bool = true
@export var title_hold: float = 0.70
@export var title_fade: float = 0.20

@export var titles: Dictionary = {
	"res://scenes/levels/Level_01.tscn": "SOUNDCHECK",
	"res://scenes/levels/Level_02.tscn": "STATIC ALLEY",
	"res://scenes/levels/Level_03.tscn": "ASCESA ROTTA",
	"res://scenes/levels/Level_04.tscn": "ECO SOSPESO"
}

@export var subtitles: Dictionary = {
	"res://scenes/levels/Level_01.tscn": "Dario — dopo l'espulsione",
	"res://scenes/levels/Level_02.tscn": "Il rumore prova a divorare tutto",
	"res://scenes/levels/Level_03.tscn": "Una salita tra eco e silenzio",
	"res://scenes/levels/Level_04.tscn": "Il ritmo resiste nel vuoto"
}

# Screenshake tuning (base)
@export var shake_decay: float = 18.0

var current_level: Node = null
var current_level_scene: PackedScene = null  # Memorizza la scena corrente per il reload

@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect
@onready var title_label: Label = $TransitionLayer/TitleLabel
@onready var subtitle_label: Label = $TransitionLayer/SubtitleLabel
@onready var sfx_player: AudioStreamPlayer2D = $TransitionLayer/SfxPlayer
@onready var cam: Camera2D = $Camera2D

# Shake state
var _shake_time: float = 0.0
var _shake_strength: float = 0.0
var _cam_base_offset: Vector2 = Vector2.ZERO


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	if first_level == null:
		push_error("[Main] first_level non impostato!")
		return

	_cam_base_offset = cam.offset

	fade_rect.modulate.a = 1.0
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0

	await load_level(first_level, false)
	await _fade_to(0.0)


func _process(delta: float) -> void:
	# Camera follow Player (semplice e stabile)
	var p := GameManager.get_player()
	if p and p is Node2D:
		cam.global_position = (p as Node2D).global_position

	# Screenshake
	if _shake_time > 0.0:
		_shake_time -= delta
		_shake_strength = max(0.0, _shake_strength - shake_decay * delta)

		# Offset casuale (niente colori, niente librerie)
		var ox := randf_range(-_shake_strength, _shake_strength)
		var oy := randf_range(-_shake_strength, _shake_strength)
		cam.offset = _cam_base_offset + Vector2(ox, oy)
	else:
		cam.offset = _cam_base_offset


# Chiamata da GameManager.screenshake()
func shake(duration: float, strength: float) -> void:
	_shake_time = max(_shake_time, duration)
	_shake_strength = max(_shake_strength, strength)


func load_level(scene: PackedScene, use_fade: bool = true, show_title: bool = true) -> void:
	if scene == null:
		push_error("[Main] load_level: scena null")
		return

	# Reset time_scale prima di qualsiasi transizione (importante per hitstop)
	Engine.time_scale = 1.0

	_set_player_enabled(false)

	if use_fade:
		await _fade_to(1.0)

	if current_level != null and is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null

	current_level = scene.instantiate()
	current_level.name = "CurrentLevel"
	add_child(current_level)

	# Memorizza la scena per il reload
	current_level_scene = scene
	# Aggiorna path corrente anche in GameManager per debug/flag
	if Engine.has_singleton("GameManager"):
		GameManager.current_level_path = scene.resource_path

	# Mostra title card solo se richiesto (per reload possiamo saltarlo)
	if show_title_card and show_title:
		await _show_title_for_scene(scene)

	if use_fade:
		await _fade_to(0.0)

	_set_player_enabled(true)
	d("[Main] Caricato livello: %s" % scene.resource_path)


func _fade_to(target_alpha: float) -> void:
	var t := get_tree().create_tween()
	t.tween_property(fade_rect, "modulate:a", target_alpha, fade_time)
	await t.finished


func _show_title_for_scene(scene: PackedScene) -> void:
	var key := scene.resource_path

	var title := ""
	if titles.has(key):
		title = str(titles[key])
	else:
		title = key.get_file().get_basename().to_upper()

	var subtitle := ""
	if subtitles.has(key):
		subtitle = str(subtitles[key])
	else:
		subtitle = ""

	title_label.text = title
	subtitle_label.text = subtitle

	if sfx_player and sfx_player.stream:
		sfx_player.play()

	var t1 := get_tree().create_tween()
	t1.tween_property(title_label, "modulate:a", 1.0, title_fade)
	t1.tween_property(subtitle_label, "modulate:a", 1.0, title_fade)
	await t1.finished

	await get_tree().create_timer(title_hold).timeout

	var t2 := get_tree().create_tween()
	t2.tween_property(title_label, "modulate:a", 0.0, title_fade)
	t2.tween_property(subtitle_label, "modulate:a", 0.0, title_fade)
	await t2.finished


func reload_current_level(use_fade: bool = true, show_title: bool = false) -> void:
	"""Ricarica il livello corrente. Per default usa fade ma non mostra title card."""
	if current_level_scene == null:
		push_error("[Main] reload_current_level: nessun livello corrente memorizzato")
		return

	d("[Main] Reload livello: %s" % current_level_scene.resource_path)
	await load_level(current_level_scene, use_fade, show_title)


func _set_player_enabled(enabled: bool) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node:
			p.set_physics_process(enabled)
			p.set_process_input(enabled)
			p.set_process_unhandled_input(enabled)
