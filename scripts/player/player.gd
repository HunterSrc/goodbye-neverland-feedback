extends CharacterBody2D

@export var speed := 220.0
@export var jump_force := -420.0
@export var gravity := 1200.0

@export var dash_speed := 600.0
@export var dash_duration := 0.10
@export var dash_cooldown := 0.3

@export var attack_duration := 0.1

@export var beat_interval := 0.4
@export var rhythm_window := 0.1

@export var feedback_max := 100.0
@export var feedback_per_hit := 15.0
@export var feedback_decay := 10.0

@export var debug_enabled: bool = false

var is_attacking := false
var is_dashing := false
var dash_timer := 0.0
var dash_cd := 0.0
var dash_dir := 1.0

var beat_timer := 0.0
var feedback := 0.0


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	# Hitbox sempre "monitoring", ma shape disabilitata finché non attacchi
	$AttackHitbox.monitoring = true
	$AttackHitbox/CollisionShape2D.disabled = true
	add_to_group("player")
	d("[Player] Ready. attack hitbox armed=false")


func _physics_process(delta: float) -> void:
	# dash cooldown timer
	if dash_cd > 0.0:
		dash_cd -= delta

	# beat timer
	beat_timer += delta
	if beat_timer >= beat_interval:
		beat_timer = 0.0
		if debug_enabled:
			d("[Player] BEAT tick")

	# feedback decay
	if feedback > 0.0:
		feedback = max(0.0, feedback - feedback_decay * delta)

	# start dash
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and not is_dashing:
		var dir := Input.get_axis("move_left", "move_right")
		if dir != 0:
			dash_dir = dir
		is_dashing = true
		dash_timer = dash_duration
		dash_cd = dash_cooldown
		d("[Player] DASH start dir=%s dur=%.3f cd=%.3f" % [str(dash_dir), dash_duration, dash_cooldown])

	# gravity (solo se non dash)
	if not is_dashing:
		if not is_on_floor():
			velocity.y += gravity * delta

	# movement (solo se non dash)
	if not is_dashing:
		var move_dir := Input.get_axis("move_left", "move_right")
		velocity.x = move_dir * speed
	else:
		velocity.x = dash_dir * dash_speed
		velocity.y = 0.0
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			d("[Player] DASH end")

	# jump (disabilitato durante dash)
	if not is_dashing and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		d("[Player] JUMP")

	# attack (hitbox attiva via shape)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		$AttackHitbox/CollisionShape2D.disabled = false

		var on_beat := is_on_beat()
		d("[Player] ATTACK start on_beat=%s" % str(on_beat))

		if on_beat:
			feedback = min(feedback + feedback_per_hit, feedback_max)
			d("[Player] FEEDBACK +%.2f => %.2f/%.2f" % [feedback_per_hit, feedback, feedback_max])

		await get_tree().create_timer(attack_duration).timeout
		$AttackHitbox/CollisionShape2D.disabled = true
		is_attacking = false
		d("[Player] ATTACK end")

	move_and_slide()


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
