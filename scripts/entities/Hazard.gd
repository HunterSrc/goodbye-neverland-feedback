extends Area2D

# Hazard semplice per testare il sistema di danno
# Chiama take_damage sul player quando entra nell'area

@export var damage_amount: int = 1
@export var debug_enabled: bool = false

var player: CharacterBody2D = null


func d(msg: String) -> void:
	if debug_enabled:
		print("[Hazard] " + msg)


func _ready() -> void:
	# Trova il player tramite gruppo
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_warning("[Hazard] Player non trovato (group 'player')")
	
	# Connetti il segnale body_entered
	body_entered.connect(_on_body_entered)
	d("Ready. damage_amount = %d" % damage_amount)


func _on_body_entered(body: Node2D) -> void:
	# Verifica che sia il player
	if not body.is_in_group("player"):
		return
	
	if player == null:
		player = body as CharacterBody2D
		if player == null:
			return
	
	d("Player entered! Applying damage %d" % damage_amount)
	
	# Chiama take_damage sul player
	if player.has_method("take_damage"):
		player.take_damage(damage_amount, global_position)
	else:
		push_error("[Hazard] Player non ha metodo take_damage()")

