extends Node

@export var first_level: PackedScene
@export var debug_enabled: bool = false

@export var fade_time: float = 0.30

@export var show_title_card: bool = true
@export var title_hold: float = 0.70
@export var title_fade: float = 0.20

# Titoli per scena (chiave = path della scena)
@export var titles: Dictionary = {
	"res://scenes/levels/Level_01.tscn": "SOUNDCHECK",
	"res://scenes/levels/Level_02.tscn": "STATIC ALLEY"
}

# Sottotitoli per scena
@export var subtitles: Dictionary = {
	"res://scenes/levels/Level_01.tscn": "Dario — dopo l'espulsione",
	"res://scenes/levels/Level_02.tscn": "Il rumore prova a divorare tutto"
}

var current_level: Node = null

@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect
@onready var title_label: Label = $TransitionLayer/TitleLabel
@onready var subtitle_label: Label = $TransitionLayer/SubtitleLabel
@onready var sfx_player: AudioStreamPlayer = $TransitionLayer/SfxPlayer


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	if first_level == null:
		push_error("[Main] first_level non impostato!")
		return

	# Start in nero
	fade_rect.modulate.a = 1.0
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0

	# Carica primo livello (senza fade-out perché siamo già neri)
	await load_level(first_level, false)

	# Fade in iniziale
	await _fade_to(0.0)


func load_level(scene: PackedScene, use_fade: bool = true) -> void:
	if scene == null:
		push_error("[Main] load_level: scena null")
		return

	# Blocca input/movimento prima della transizione
	_set_player_enabled(false)

	if use_fade:
		await _fade_to(1.0)

	# Rimuovi livello attuale
	if current_level != null and is_instance_valid(current_level):
		d("[Main] Rimuovo livello: %s" % current_level.name)
		current_level.queue_free()
		current_level = null

	# Istanzia nuovo livello
	current_level = scene.instantiate()
	current_level.name = "CurrentLevel"
	add_child(current_level)

	# Title card (mentre siamo neri o subito dopo)
	if show_title_card:
		await _show_title_for_scene(scene)

	if use_fade:
		await _fade_to(0.0)

	# Sblocca input/movimento dopo la transizione
	_set_player_enabled(true)

	d("[Main] Caricato livello: %s" % scene.resource_path)


func _fade_to(target_alpha: float) -> void:
	var t := get_tree().create_tween()
	t.tween_property(fade_rect, "modulate:a", target_alpha, fade_time)
	await t.finished


func _show_title_for_scene(scene: PackedScene) -> void:
	var key := scene.resource_path

	# Title
	var title := ""
	if titles.has(key):
		title = str(titles[key])
	else:
		title = key.get_file().get_basename().to_upper()

	# Subtitle
	var subtitle := ""
	if subtitles.has(key):
		subtitle = str(subtitles[key])
	else:
		subtitle = ""

	title_label.text = title
	subtitle_label.text = subtitle

	# Whoosh SFX
	if sfx_player and sfx_player.stream:
		sfx_player.play()

	# Fade in (titolo + sottotitolo insieme)
	var t1 := get_tree().create_tween()
	t1.tween_property(title_label, "modulate:a", 1.0, title_fade)
	t1.tween_property(subtitle_label, "modulate:a", 1.0, title_fade)
	await t1.finished

	# Hold
	await get_tree().create_timer(title_hold).timeout

	# Fade out
	var t2 := get_tree().create_tween()
	t2.tween_property(title_label, "modulate:a", 0.0, title_fade)
	t2.tween_property(subtitle_label, "modulate:a", 0.0, title_fade)
	await t2.finished


func _set_player_enabled(enabled: bool) -> void:
	# Richiede che il Player sia nel gruppo "player"
	for p in get_tree().get_nodes_in_group("player"):
		if p is Node:
			p.set_physics_process(enabled)
			p.set_process_input(enabled)
			p.set_process_unhandled_input(enabled)
