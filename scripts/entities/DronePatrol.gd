extends CharacterBody2D

# Drone Patrol: nemico che pattuglia un'area e infligge danno al contatto

@export var patrol_speed: float = 80.0
@export var patrol_distance: float = 200.0  # distanza totale del percorso
@export var damage_amount: int = 1
@export var debug_enabled: bool = false
@export var min_hits_to_die: int = 2
@export var max_hits_to_die: int = 4

var start_position: Vector2
var patrol_direction: float = 1.0  # 1 = destra, -1 = sinistra
var distance_traveled: float = 0.0
var hits_remaining: int = 1

var player: CharacterBody2D = null


func d(msg: String) -> void:
	if debug_enabled:
		print("[DronePatrol] " + msg)


func _ready() -> void:
	start_position = global_position
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	hits_remaining = randi_range(min_hits_to_die, max_hits_to_die)
	
	# Connetti il segnale per contact damage
	var hit_area = get_node_or_null("HitArea")
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)
		hit_area.area_entered.connect(_on_hit_area_area_entered)
	else:
		push_warning("[DronePatrol] HitArea non trovata!")
	
	d("Ready. patrol_distance = %s, speed = %s" % [patrol_distance, patrol_speed])


func _physics_process(delta: float) -> void:
	# Movimento di pattuglia
	var move_amount = patrol_speed * delta * patrol_direction
	velocity.x = move_amount
	velocity.y = 0.0  # Il drone vola, non ha gravità
	
	# Aggiorna distanza percorsa
	distance_traveled += abs(move_amount)
	
	# Inverti direzione se hai raggiunto la distanza massima
	if distance_traveled >= patrol_distance:
		patrol_direction *= -1.0
		distance_traveled = 0.0
		d("Patrol direction reversed")
	
	# Applica movimento
	move_and_slide()


func _on_hit_area_body_entered(body: Node2D) -> void:
	# Verifica che sia il player
	if not body.is_in_group("player"):
		return
	
	if player == null:
		player = body as CharacterBody2D
		if player == null:
			return
	
	d("Player hit! Applying damage %d" % damage_amount)
	
	# Infliggi danno al player
	if player.has_method("take_damage"):
		player.take_damage(damage_amount, global_position)
		# Hitstop e screenshake (come richiesto nel brief)
		GameManager.hitstop(0.04, 0.05)
		GameManager.screenshake(0.08, 4.0)
	else:
		push_error("[DronePatrol] Player non ha metodo take_damage()")


func _on_hit_area_area_entered(area: Area2D) -> void:
	# Rileva attacco del player (AttackHitbox è Area2D layer 4)
	if not area.has_method("is_attack_active"):
		return
	if not area.is_attack_active():
		return

	hits_remaining -= 1
	d("Drone hit! remaining=%d" % hits_remaining)
	GameManager.hitstop(0.04, 0.05)
	GameManager.screenshake(0.08, 4.0)
	if hits_remaining <= 0:
		queue_free()
