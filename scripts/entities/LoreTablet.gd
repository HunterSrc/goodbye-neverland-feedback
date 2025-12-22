extends Area2D

# LoreTablet: tablet interattiva che mostra testo quando il player interagisce
# Usa il tasto "interact" per leggere

@export var lore_text: String = "Testo di esempio\nLinea 2"
@export var debug_enabled: bool = false
@export var prompt_text: String = "[E] Leggi"
@export var prompt_fade_time: float = 0.12

var player: CharacterBody2D = null
var is_player_nearby: bool = false
var is_reading: bool = false
var prompt_node: CanvasItem = null
var prompt_tween: Tween = null


func d(msg: String) -> void:
	if debug_enabled:
		print("[LoreTablet] " + msg)


func _ready() -> void:
	# Trova il player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_warning("[LoreTablet] Player non trovato (group 'player')")
	
	# Connetti i segnali
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	prompt_node = get_node_or_null("Prompt") as CanvasItem
	if prompt_node:
		if prompt_node is Label:
			(prompt_node as Label).text = prompt_text
		prompt_node.visible = false
		prompt_node.modulate.a = 0.0
	
	d("Ready. lore_text length = %d" % lore_text.length())


func _process(_delta: float) -> void:
	# Controlla input interact solo se il player è vicino e non sta già leggendo
	if is_player_nearby and not is_reading and Input.is_action_just_pressed("interact"):
		_show_lore()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		if player == null:
			player = body as CharacterBody2D
		d("Player entered area")
		_show_prompt(true)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		d("Player exited area")
		_show_prompt(false)


func _show_prompt(should_show: bool) -> void:
	if prompt_node == null:
		prompt_node = get_node_or_null("Prompt") as CanvasItem
		if prompt_node and prompt_node is Label and prompt_text != "":
			(prompt_node as Label).text = prompt_text
		if prompt_node == null:
			return

	if prompt_tween and prompt_tween.is_running():
		prompt_tween.kill()

	prompt_node.visible = true
	prompt_tween = create_tween()
	var target := 1.0 if should_show else 0.0
	prompt_tween.tween_property(prompt_node, "modulate:a", target, prompt_fade_time)

	if not should_show:
		prompt_tween.finished.connect(func():
			if prompt_node:
				prompt_node.visible = false
		)


func _show_lore() -> void:
	if is_reading:
		return
	
	is_reading = true
	d("Showing lore: %s" % lore_text)
	_show_prompt(false)
	
	# Blocca il movimento del player
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(false)
		player.set_process_input(false)
	
	# Mostra l'UI del lore
	var lore_ui = get_tree().get_first_node_in_group("lore_ui")
	if lore_ui and lore_ui.has_method("show_lore"):
		lore_ui.show_lore(lore_text)
		# Aspetta che l'utente chiuda il lore
		await lore_ui.lore_closed
	else:
		push_warning("[LoreTablet] LoreUI non trovato (group 'lore_ui')")
		# Fallback: aspetta un momento e riabilita
		await get_tree().create_timer(1.0).timeout
	
	# Riabilita il movimento del player
	if player and player.has_method("set_physics_process"):
		player.set_physics_process(true)
		player.set_process_input(true)
	
	is_reading = false
	d("Lore closed")
