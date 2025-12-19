extends CharacterBody2D

@export var speed := 220.0
@export var jump_force := -420.0
@export var gravity := 1200.0

# DASH (snappy)
@export var dash_speed := 900.0
@export var dash_duration := 0.10
@export var dash_cooldown := 0.30

@export var attack_duration := 0.10

@export var beat_interval := 0.40
@export var rhythm_window := 0.10

@export var feedback_max := 100.0
@export var feedback_per_hit := 15.0
@export var feedback_decay := 10.0

# Facing / Hitbox
@export var hitbox_offset_x: float = 30.0

# Facing lock: blocca il giro durante l'attacco + piccolo delay dopo
@export var facing_lock_extra: float = 0.06
var facing_lock_timer: float = 0.0

# --- I-FRAMES / DAMAGE ---
@export var max_hp: int = 3
@export var i_frame_time: float = 0.5
@export var blink_interval: float = 0.06
@export var hurt_knockback: Vector2 = Vector2(280, -220)
@export var respawn_position: Vector2 = Vector2(120, 520)

var hp: int = 3
var invuln_timer: float = 0.0
var _blink_running: bool = false

@export var debug_enabled: bool = false

var is_attacking := false
var is_dashing := false
var dash_timer := 0.0
var dash_cd := 0.0
var dash_dir := 1.0

# Extra polish: 1 air dash per salto
var can_air_dash := true

var beat_timer := 0.0
var feedback := 0.0

# Facing state
var facing: int = 1

@onready var sprite: Node = get_node_or_null("Sprite")
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	add_to_group("player")

	hp = max_hp

	# Hitbox: Area sempre monitoring, shape disabilitata finché non attacchi
	$AttackHitbox.monitoring = true
	$AttackHitbox/CollisionShape2D.disabled = true

	# Posiziona hitbox iniziale in base al facing
	_apply_visual_and_hitbox()

	d("[Player] Ready HP=%d/%d" % [hp, max_hp])


func _physics_process(delta: float) -> void:
	# Reset air dash quando tocchi terra
	if is_on_floor():
		can_air_dash = true

	# dash cooldown timer
	if dash_cd > 0.0:
		dash_cd -= delta

	# facing lock timer
	if facing_lock_timer > 0.0:
		facing_lock_timer -= delta

	# invulnerability timer (i-frames)
	if invuln_timer > 0.0:
		invuln_timer -= delta

	# beat timer
	beat_timer += delta
	if beat_timer >= beat_interval:
		beat_timer = 0.0
		if debug_enabled:
			d("[Player] BEAT tick")

	# feedback decay
	if feedback > 0.0:
		feedback = max(0.0, feedback - feedback_decay * delta)

	# --- DASH start (può partire anche in aria) ---
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and not is_dashing:
		# se sei in aria e hai già usato l'air dash, blocca
		if not is_on_floor() and not can_air_dash:
			d("[Player] DASH blocked (no air dash left)")
		else:
			var dir := Input.get_axis("move_left", "move_right")
			if dir != 0.0:
				dash_dir = dir
				# aggiorna facing anche per dash, ma solo se non sei in lock
				_try_update_facing_from_dir(dash_dir)

			is_dashing = true
			dash_timer = dash_duration
			dash_cd = dash_cooldown

			if not is_on_floor():
				can_air_dash = false

			d("[Player] DASH start dir=%s air=%s" % [str(dash_dir), str(not is_on_floor())])

	# --- GRAVITÀ (sempre, anche durante dash) ---
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- MOVIMENTO ORIZZONTALE ---
	if is_dashing:
		# forziamo solo X, NON tocchiamo Y (gravità resta attiva)
		velocity.x = dash_dir * dash_speed

		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			d("[Player] DASH end")
	else:
		var move_dir := Input.get_axis("move_left", "move_right")

		# aggiorna facing SOLO se non in lock (attack lock / post-attack delay)
		_try_update_facing_from_dir(move_dir)

		velocity.x = move_dir * speed

	# --- JUMP (lockout: niente jump durante dash) ---
	if not is_dashing and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		d("[Player] JUMP")

	# --- ATTACK (hitbox via shape enable/disable) ---
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true

		# lock facing per tutta la durata dell'attacco + extra
		facing_lock_timer = attack_duration + facing_lock_extra

		# assicura che la hitbox sia “davanti” al facing corrente
		_apply_visual_and_hitbox()

		$AttackHitbox/CollisionShape2D.disabled = false

		var on_beat := is_on_beat()
		d("[Player] ATTACK start on_beat=%s facing=%s" % [str(on_beat), str(facing)])

		if on_beat:
			feedback = min(feedback + feedback_per_hit, feedback_max)
			d("[Player] FEEDBACK +%.2f => %.2f/%.2f" % [feedback_per_hit, feedback, feedback_max])

		await get_tree().create_timer(attack_duration).timeout
		$AttackHitbox/CollisionShape2D.disabled = true
		is_attacking = false
		d("[Player] ATTACK end")

	move_and_slide()


func _try_update_facing_from_dir(dir: float) -> void:
	# se stai attaccando o sei nel delay post-attacco, NON cambiare facing
	if is_attacking or facing_lock_timer > 0.0:
		return

	var new_facing := facing
	if dir > 0.0:
		new_facing = 1
	elif dir < 0.0:
		new_facing = -1

	if new_facing != facing:
		facing = new_facing
		_apply_visual_and_hitbox()


func _apply_visual_and_hitbox() -> void:
	# flip sprite
	if sprite and sprite is Sprite2D:
		(sprite as Sprite2D).flip_h = (facing == -1)
	elif sprite and sprite is AnimatedSprite2D:
		(sprite as AnimatedSprite2D).flip_h = (facing == -1)

	# sposta hitbox davanti al player
	if attack_hitbox_shape:
		attack_hitbox_shape.position.x = hitbox_offset_x * float(facing)


func is_on_beat() -> bool:
	return beat_timer <= rhythm_window or beat_timer >= beat_interval - rhythm_window


func consume_feedback(amount: float) -> bool:
	var ok := feedback >= amount
	if ok:
		feedback -= amount
		d("[Player] consume_feedback %.2f OK -> %.2f" % [amount, feedback])
	else:
		d("[Player] consume_feedback %.2f FAIL (have %.2f)" % [amount, feedback])
	return ok


# -----------------------------
# DAMAGE + I-FRAMES API
# Chiamala dai nemici: player.take_damage(1, global_position)
# -----------------------------
func take_damage(amount: int, from_global_pos: Vector2 = Vector2.ZERO) -> void:
	# i-frames attivi -> ignora
	if invuln_timer > 0.0:
		d("[Player] Damage ignored (i-frames)")
		return

	hp = max(0, hp - amount)
	invuln_timer = i_frame_time
	d("[Player] Took damage %d -> HP %d/%d" % [amount, hp, max_hp])

	# Knockback
	var dir := float(facing)
	if from_global_pos != Vector2.ZERO:
		dir = sign(global_position.x - from_global_pos.x)
		if dir == 0:
			dir = float(facing)

	velocity.x = dir * hurt_knockback.x
	velocity.y = hurt_knockback.y

	_start_blink()

	if hp <= 0:
		_die()


func _start_blink() -> void:
	if _blink_running:
		return
	if not sprite:
		return
	if not (sprite is CanvasItem):
		return

	_blink_running = true
	_blink_loop()


func _blink_loop() -> void:
	var s := sprite as CanvasItem
	while invuln_timer > 0.0 and is_inside_tree():
		s.visible = false
		await get_tree().create_timer(blink_interval, false, false, true).timeout
		s.visible = true
		await get_tree().create_timer(blink_interval, false, false, true).timeout

	s.visible = true
	_blink_running = false


func _die() -> void:
	d("[Player] DEAD -> respawn")
	global_position = respawn_position
	velocity = Vector2.ZERO
	hp = max_hp
	invuln_timer = 0.0
	# garantisce che torni visibile
	if sprite and sprite is CanvasItem:
		(sprite as CanvasItem).visible = true
	_blink_running = false
