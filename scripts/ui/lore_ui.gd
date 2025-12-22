extends CanvasLayer

# LoreUI: UI per mostrare il testo delle LoreTablet
# Supporta typewriter effect opzionale

@export var typewriter_enabled: bool = true
@export var typewriter_speed: float = 0.05  # secondi per carattere
@export var fade_time: float = 0.2

signal lore_closed

var is_showing: bool = false

@onready var panel: Panel = $LorePanel
@onready var text_label: RichTextLabel = $LorePanel/TextLabel
@onready var close_hint: Label = $LorePanel/CloseHint


func _ready() -> void:
	add_to_group("lore_ui")
	panel.visible = false
	text_label.bbcode_enabled = true
	close_hint.text = "Premi [E] per chiudere"


func _input(event: InputEvent) -> void:
	# Chiudi il lore con il tasto interact o qualsiasi altro input
	if is_showing and Input.is_action_just_pressed("interact"):
		_close_lore()
	elif is_showing and event is InputEventKey and event.pressed:
		# Chiudi anche con qualsiasi altro tasto (opzionale)
		_close_lore()


func show_lore(text: String) -> void:
	if is_showing:
		return
	
	is_showing = true
	text_label.text = ""
	panel.visible = true
	
	# Fade in
	var tween = create_tween()
	panel.modulate.a = 0.0
	tween.tween_property(panel, "modulate:a", 1.0, fade_time)
	await tween.finished
	
	# Mostra il testo (con typewriter se abilitato)
	if typewriter_enabled:
		await _typewriter_text(text)
	else:
		text_label.text = text
	
	# Aspetta che l'utente chiuda (il segnale viene emesso da _close_lore)
	await lore_closed


func _typewriter_text(text: String) -> void:
	# Typewriter effect: mostra il testo carattere per carattere
	var current_text := ""
	
	for i in range(text.length()):
		current_text += text[i]
		text_label.text = current_text
		await get_tree().create_timer(typewriter_speed).timeout


func _close_lore() -> void:
	if not is_showing:
		return
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, fade_time)
	await tween.finished
	
	panel.visible = false
	is_showing = false
	text_label.text = ""
	
	# Emetti il segnale
	lore_closed.emit()

