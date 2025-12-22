extends StaticBody2D

@export var feedback_required: float = 30.0
@export var debug_enabled: bool = false

var player: CharacterBody2D
var is_breaking: bool = false


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	# Reset stato iniziale (importante per reload)
	is_breaking = false
	
	add_to_group("noise_block")
	if Engine.has_singleton("GameManager"):
		GameManager.register_noise_block(self)
	
	# Trova il player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		push_warning("NoiseBlock: Player non trovato (group 'player').")

	if not $HitArea:
		push_error("NoiseBlock: HitArea non trovata!")
		return

	# Assicurati che la HitArea sia abilitata e monitoring
	$HitArea.monitoring = true
	if $HitArea.has_node("CollisionShape2D"):
		$HitArea/CollisionShape2D.disabled = false
	
	# Connetti il segnale (disconnetti prima se già connesso per evitare duplicati)
	if $HitArea.area_entered.is_connected(_on_hit_area_entered):
		$HitArea.area_entered.disconnect(_on_hit_area_entered)
	$HitArea.area_entered.connect(_on_hit_area_entered)
	
	d("[NoiseBlock] Ready. feedback_required = %s" % feedback_required)


func _on_hit_area_entered(area: Area2D) -> void:
	d("[NoiseBlock] HitArea entered by: %s" % area.name)

	if is_breaking:
		d("[NoiseBlock] Ignoro: già in break")
		return

	if area.has_method("is_attack_active"):
		var active := bool(area.is_attack_active())
		d("[NoiseBlock] is_attack_active() = %s" % str(active))
		if not active:
			d("[NoiseBlock] Ignoro: attacco non attivo")
			return
	else:
		d("[NoiseBlock] WARNING: l'area non ha is_attack_active()")

	if not area.has_method("is_on_beat_attack"):
		d("[NoiseBlock] Ignoro: l'area non ha is_on_beat_attack()")
		return

	var on_beat: bool = bool(area.is_on_beat_attack())
	d("[NoiseBlock] on_beat = %s" % str(on_beat))

	if not on_beat:
		d("[NoiseBlock] Fuori tempo: nessun effetto")
		return

	# --- HIT CONFIRMED -> micro polish ---
	GameManager.hitstop()
	GameManager.screenshake()
	GameManager.play_hit_on_beat()  # SFX hit

	# Feedback visivo immediato
	if $AnimationPlayer and $AnimationPlayer.has_animation("hit_on_beat"):
		$AnimationPlayer.play("hit_on_beat")
	else:
		d("[NoiseBlock] WARNING: manca animazione 'hit_on_beat'")
	
	# Particelle hit
	_spawn_hit_particles()

	# Aggiorna riferimento al player se null (può succedere dopo reload)
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player == null:
			d("[NoiseBlock] ERROR: player non trovato")
			return

	d("[NoiseBlock] Player feedback = %s, richiesto = %s" % [str(player.feedback), str(feedback_required)])

	if player.consume_feedback(feedback_required):
		d("[NoiseBlock] Feedback OK -> break")
		break_block()
	else:
		d("[NoiseBlock] Feedback NON sufficiente -> resta intero")


func break_block() -> void:
	is_breaking = true

	if $HitArea:
		$HitArea.set_deferred("monitoring", false)
		if $HitArea.has_node("CollisionShape2D"):
			$HitArea/CollisionShape2D.set_deferred("disabled", true)

	# Particelle break
	_spawn_break_particles()

	if $AnimationPlayer and $AnimationPlayer.has_animation("break"):
		$AnimationPlayer.play("break")
		await $AnimationPlayer.animation_finished
	else:
		d("[NoiseBlock] WARNING: manca animazione 'break' (elimino subito)")

	d("[NoiseBlock] queue_free()")
	if Engine.has_singleton("GameManager"):
		GameManager.noise_block_destroyed()
	queue_free()


func _spawn_hit_particles() -> void:
	# Carica e spawna particelle hit
	var particles_scene = load("res://scenes/vfx/HitParticles.tscn")
	if particles_scene:
		var particles = particles_scene.instantiate()
		get_tree().current_scene.add_child(particles)
		particles.global_position = global_position
		particles.emit(global_position)
		# Rimuovi dopo un momento (usa timer invece di await)
		get_tree().create_timer(1.0).timeout.connect(func(): 
			if is_instance_valid(particles):
				particles.queue_free()
		)


func _spawn_break_particles() -> void:
	# Carica e spawna particelle break
	var particles_scene = load("res://scenes/vfx/BreakParticles.tscn")
	if particles_scene:
		var particles = particles_scene.instantiate()
		get_tree().current_scene.add_child(particles)
		particles.global_position = global_position
		particles.emit(global_position)
		# Rimuovi dopo un momento (usa timer invece di await)
		get_tree().create_timer(1.0).timeout.connect(func(): 
			if is_instance_valid(particles):
				particles.queue_free()
		)
