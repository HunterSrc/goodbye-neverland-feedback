extends StaticBody2D

@export var feedback_required: float = 30.0
@export var debug_enabled: bool = false

var player: CharacterBody2D
var is_breaking: bool = false


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if player == null:
		push_warning("NoiseBlock: Player non trovato (group 'player').")

	if not $HitArea:
		push_error("NoiseBlock: HitArea non trovata!")
		return

	$HitArea.area_entered.connect(_on_hit_area_entered)
	d("[NoiseBlock] Ready. feedback_required = %s" % feedback_required)


func _on_hit_area_entered(area: Area2D) -> void:
	d("[NoiseBlock] HitArea entered by: %s" % area.name)

	if is_breaking:
		d("[NoiseBlock] Ignoro: già in break")
		return

	# Filtra falsi positivi: se l'hitbox espone is_attack_active, deve essere attiva
	if area.has_method("is_attack_active"):
		var active := bool(area.is_attack_active())
		d("[NoiseBlock] is_attack_active() = %s" % str(active))
		if not active:
			d("[NoiseBlock] Ignoro: attacco non attivo")
			return
	else:
		d("[NoiseBlock] WARNING: l'area non ha is_attack_active()")

	# Serve sapere se è a tempo
	if not area.has_method("is_on_beat_attack"):
		d("[NoiseBlock] Ignoro: l'area non ha is_on_beat_attack()")
		return

	var on_beat: bool = bool(area.is_on_beat_attack())
	d("[NoiseBlock] on_beat = %s" % str(on_beat))

	if not on_beat:
		d("[NoiseBlock] Fuori tempo: nessun effetto")
		return

	# Feedback visivo immediato
	if $AnimationPlayer and $AnimationPlayer.has_animation("hit_on_beat"):
		$AnimationPlayer.play("hit_on_beat")
	else:
		d("[NoiseBlock] WARNING: manca animazione 'hit_on_beat'")

	# Rompi solo se feedback sufficiente
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

	# NON cambiare monitoring direttamente dentro un callback di segnale:
	# usa set_deferred per evitare "locked during in/out signal"
	if $HitArea:
		$HitArea.set_deferred("monitoring", false)
		# opzionale ma consigliato: disabilita anche la collisione della HitArea
		if $HitArea.has_node("CollisionShape2D"):
			$HitArea/CollisionShape2D.set_deferred("disabled", true)

	if $AnimationPlayer and $AnimationPlayer.has_animation("break"):
		$AnimationPlayer.play("break")
		await $AnimationPlayer.animation_finished
	else:
		d("[NoiseBlock] WARNING: manca animazione 'break' (elimino subito)")

	d("[NoiseBlock] queue_free()")
	queue_free()
