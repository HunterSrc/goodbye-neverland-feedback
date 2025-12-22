extends Control

# UI per mostrare i cuori HP del player
# Si aggiorna automaticamente quando il player prende danno

@export var heart_size: Vector2 = Vector2(32, 32)
@export var heart_spacing: float = 8.0
@export var heart_color_full: Color = Color(1.0, 0.2, 0.2, 1.0)  # Rosso
@export var heart_color_empty: Color = Color(0.3, 0.3, 0.3, 0.5)  # Grigio trasparente

@export var shake_strength: float = 4.0
@export var shake_duration: float = 0.15
@export var pop_scale: float = 1.3
@export var pop_duration: float = 0.1
@export var flash_color: Color = Color(1.0, 0.2, 0.2, 0.6)
@export var flash_duration: float = 0.18

var max_hp: int = 3
var current_hp: int = 3
var hearts: Array[Control] = []
var player: CharacterBody2D = null
var _damage_flash: ColorRect = null

@onready var hearts_container: HBoxContainer = $HeartsContainer


func _ready() -> void:
	# Trova il player e connetti i segnali se possibile, poi crea i cuori
	_bind_player(GameManager.get_player())
	_damage_flash = get_node_or_null("../DamageFlash") as ColorRect
	_create_hearts()


func _bind_player(p: CharacterBody2D) -> void:
	if player == p:
		return

	if player and player.has_signal("hp_changed") and player.hp_changed.is_connected(_on_player_hp_changed):
		player.hp_changed.disconnect(_on_player_hp_changed)

	player = p
	if player:
		max_hp = player.max_hp
		current_hp = player.hp
		if player.has_signal("hp_changed") and not player.hp_changed.is_connected(_on_player_hp_changed):
			player.hp_changed.connect(_on_player_hp_changed)
	else:
		# Fallback: valori di default
		max_hp = 3
		current_hp = 3


func _create_hearts() -> void:
	# Pulisci i cuori esistenti
	for heart in hearts:
		if is_instance_valid(heart):
			heart.queue_free()
	hearts.clear()
	
	# Crea i cuori
	for i in range(max_hp):
		var heart = _create_heart_node()
		hearts_container.add_child(heart)
		hearts.append(heart)
	
	_update_hearts_display()


func _create_heart_node() -> Control:
	# Crea un cuore usando Control con ColorRect
	var heart = Control.new()
	heart.custom_minimum_size = heart_size
	
	# Background del cuore (forma semplice)
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = heart_color_full
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	heart.add_child(bg)
	
	# Outline/bordo scuro
	var outline = ColorRect.new()
	outline.name = "Outline"
	outline.color = Color(0.1, 0.1, 0.1, 1.0)
	outline.set_anchors_preset(Control.PRESET_FULL_RECT)
	outline.offset_left = -1
	outline.offset_top = -1
	outline.offset_right = 1
	outline.offset_bottom = 1
	heart.add_child(outline)
	bg.move_to_front()
	
	# Usa un Label con emoji come alternativa visiva più chiara
	var label = Label.new()
	label.name = "HeartLabel"
	label.text = "♥"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", int(heart_size.y * 0.8))
	heart.add_child(label)
	label.move_to_front()
	
	return heart


func _update_hearts_display() -> void:
	for i in range(hearts.size()):
		var heart = hearts[i]
		if not is_instance_valid(heart):
			continue
		
		var is_full = i < current_hp
		
		# Aggiorna il background ColorRect
		var bg = heart.get_node_or_null("Background")
		if bg and bg is ColorRect:
			(bg as ColorRect).color = heart_color_full if is_full else heart_color_empty
			(bg as ColorRect).modulate.a = 1.0 if is_full else 0.4
		
		# Aggiorna il Label (emoji)
		var label = heart.get_node_or_null("HeartLabel")
		if label and label is Label:
			(label as Label).modulate = Color.WHITE if is_full else Color(0.5, 0.5, 0.5, 0.5)


func update_hp(new_hp: int, max_hp_value: int = -1) -> void:
	if max_hp_value > 0:
		max_hp = max_hp_value
		if hearts.size() != max_hp:
			_create_hearts()
	
	var old_hp = current_hp
	current_hp = clamp(new_hp, 0, max_hp)
	
	_update_hearts_display()
	
	# Se abbiamo perso HP, anima i cuori
	if current_hp < old_hp:
		_animate_damage(old_hp - current_hp)


func _animate_damage(amount: int) -> void:
	# Shake generale dell'UI
	_shake_ui()
	
	# Pop dei cuori persi
	for i in range(current_hp, min(current_hp + amount, hearts.size())):
		if i < hearts.size() and is_instance_valid(hearts[i]):
			_pop_heart(hearts[i])

	_flash_damage()


func _shake_ui() -> void:
	var original_offset = position
	var tween = create_tween()
	
	for _i in range(3):
		var shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tween.tween_property(self, "position", original_offset + shake_offset, shake_duration / 6.0)
		tween.tween_property(self, "position", original_offset, shake_duration / 6.0)
	
	# Assicura che torni alla posizione originale
	tween.tween_property(self, "position", original_offset, 0.0)


func _pop_heart(heart: Control) -> void:
	if not is_instance_valid(heart):
		return
	
	var original_scale = heart.scale
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(heart, "scale", original_scale * pop_scale, pop_duration)
	tween.tween_property(heart, "modulate:a", 0.0, pop_duration)
	
	await tween.finished
	
	# Ripristina (ma il cuore rimane vuoto)
	heart.scale = original_scale
	heart.modulate.a = 1.0


func _process(_delta: float) -> void:
	# Se il player cambia (reload livello), ricollega i segnali
	var p = GameManager.get_player()
	if p != player:
		_bind_player(p)
		_create_hearts()
	
	# Polling di sicurezza per allineare gli HP se il segnale mancasse
	if player:
		if player.hp != current_hp or player.max_hp != max_hp:
			update_hp(player.hp, player.max_hp)


func _on_player_hp_changed(new_hp: int, max_hp_value: int) -> void:
	update_hp(new_hp, max_hp_value)


func _flash_damage() -> void:
	if _damage_flash == null:
		return

	_damage_flash.color = flash_color
	var t = create_tween()
	_damage_flash.modulate.a = 0.0
	t.tween_property(_damage_flash, "modulate:a", flash_color.a, flash_duration * 0.5)
	t.tween_property(_damage_flash, "modulate:a", 0.0, flash_duration * 0.5)
