extends CharacterBody2D

signal hp_changed(new_hp: int, max_hp: int)

@export var speed := 220.0
@export var jump_force := -500.0
@export var gravity := 1200.0
@export var wall_jump_horizontal := 280.0
@export var wall_jump_vertical := -500.0
@export var wall_jump_memory := 0.12

# DASH (snappy)
@export var dash_speed := 900.0
@export var dash_duration := 0.10
@export var dash_cooldown := 0.30

@export var boomerang_distance := 76.0
@export var boomerang_out_time := 0.14
@export var boomerang_return_time := 0.156
@export var boomerang_hold_time := 0.0
# Down aim offsets
@export var hitbox_offset_y_down: float = 30.0
@export var hitbox_offset_x_down: float = 8.0
# Pogo
@export var pogo_velocity: float = -380.0
# Up aim offsets
@export var hitbox_offset_y_up: float = -30.0
@export var hitbox_offset_x_up: float = 8.0
@export var boomerang_wall_padding: float = 4.0

@export var beat_interval := 0.40
@export var rhythm_window := 0.10

@export var feedback_max := 100.0
@export var feedback_per_hit := 15.0
@export var feedback_decay := 10.0
@export var attack_windup: float = 0.08

# Facing / Hitbox
@export var hitbox_offset_x: float = 30.0

# Facing lock: blocca il giro durante l'attacco + piccolo delay dopo
@export var facing_lock_extra: float = 0.06
var facing_lock_timer: float = 0.0

# --- HP / DAMAGE / RESPAWN ---
@export var max_hp: int = 3
@export var i_frame_time: float = 0.5
@export var blink_interval: float = 0.06
@export var hurt_knockback: Vector2 = Vector2(280, -220)
@export var damage_shake_enabled: bool = true
@export var damage_shake_duration: float = 0.10
@export var damage_shake_strength: float = 4.0

@export var respawn_delay: float = 0.6
@export var respawn_fallback: Vector2 = Vector2(120, 520) # usato se manca RespawnPoint

var hp: int = 3
var invuln_timer: float = 0.0
var _blink_running: bool = false
var respawn_position: Vector2
var _is_dead: bool = false

@export var debug_enabled: bool = false

var is_attacking := false
var _attack_active: bool = false
var _attack_on_beat: bool = false
var _attack_aim_at_start: String = "forward"
var is_dashing := false
var dash_timer := 0.0
var dash_cd := 0.0
var dash_dir := 1.0
var _boomerang_phase: int = 0  # 0=none,1=out,2=hold,3=return
var _boomerang_t: float = 0.0
var _hitbox_base: Vector2 = Vector2.ZERO
var _attack_dir: Vector2 = Vector2.RIGHT
var _attack_max_distance: float = 0.0
var pogo_used_this_attack: bool = false

# Extra polish: 1 air dash per salto
var can_air_dash := true

var beat_timer := 0.0
var feedback := 0.0

# Facing state
var facing: int = 1
const AIM_FORWARD := "forward"
const AIM_DOWN := "down"
const AIM_UP := "up"
var aim_mode: String = AIM_FORWARD
var _aim_locked: bool = false

@onready var sprite: Node = get_node_or_null("Sprite")
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var hat_spin: AnimatedSprite2D = $AttackHitbox/Hat_spin
var _attack_windup_timer: float = 0.0
var _last_wall_normal: Vector2 = Vector2.ZERO
var _last_wall_time: float = 0.0


func d(msg: String) -> void:
	if debug_enabled:
		print(msg)


func _ready() -> void:
	add_to_group("player")

	hp = max_hp
	_is_dead = false
	hp_changed.emit(hp, max_hp)

	# RespawnPoint dal livello (group "respawn")
	var rp := get_tree().get_first_node_in_group("respawn") as Node2D
	if rp:
		respawn_position = rp.global_position
	else:
		respawn_position = respawn_fallback

	# Hitbox: Area sempre monitoring, shape disabilitata finché non attacchi
	attack_hitbox.monitoring = true
	attack_hitbox_shape.disabled = true
	if attack_hitbox and attack_hitbox.has_signal("attack_hit") and not attack_hitbox.attack_hit.is_connected(_on_attack_hit):
		attack_hitbox.attack_hit.connect(_on_attack_hit)
	if hat_spin:
		hat_spin.visible = false
		hat_spin.stop()

	# Posiziona hitbox iniziale in base al facing
	_apply_visual_and_hitbox()

	d("[Player] Ready HP=%d/%d respawn=%s" % [hp, max_hp, str(respawn_position)])


func _physics_process(delta: float) -> void:
	# Reset air dash quando tocchi terra
	var grounded := is_on_floor()
	var move_dir := 0.0
	var jump_pressed := false
	_cache_wall_normal()
	if _last_wall_time > 0.0:
		_last_wall_time -= delta
	if grounded:
		can_air_dash = true
		if not _aim_locked:
			aim_mode = AIM_FORWARD

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
		# Metronomo tick (non invadente)
		GameManager.play_beat_tick()
		if debug_enabled:
			d("[Player] BEAT tick")

	# feedback decay
	if feedback > 0.0:
		feedback = max(0.0, feedback - feedback_decay * delta)

	# --- DASH start (può partire anche in aria) ---
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and not is_dashing:
		if not is_on_floor() and not can_air_dash:
			d("[Player] DASH blocked (no air dash left)")
		else:
			var dir := Input.get_axis("move_left", "move_right")
			if dir != 0.0:
				dash_dir = dir
				_try_update_facing_from_dir(dash_dir)

			is_dashing = true
			dash_timer = dash_duration
			dash_cd = dash_cooldown

			if not is_on_floor():
				can_air_dash = false

			d("[Player] DASH start dir=%s air=%s" % [str(dash_dir), str(not is_on_floor())])

	# --- GRAVITÀ (sempre, anche durante dash) ---
	if not grounded:
		velocity.y += gravity * delta

	# --- AIM (forward/down/up) ---
	if not _aim_locked:
		if debug_enabled:
			if Input.is_action_just_pressed("move_up"):
				d("[Player] INPUT move_up pressed")
			if Input.is_action_just_pressed("move_down"):
				d("[Player] INPUT move_down pressed")
		if Input.is_action_pressed("move_down"):
			aim_mode = AIM_DOWN
		elif Input.is_action_pressed("move_up"):
			aim_mode = AIM_UP
		else:
			aim_mode = AIM_FORWARD
		_apply_visual_and_hitbox()

	# --- MOVIMENTO ORIZZONTALE ---
	if is_dashing:
		velocity.x = dash_dir * dash_speed
		move_dir = dash_dir
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			d("[Player] DASH end")
	else:
		move_dir = Input.get_axis("move_left", "move_right")
		_try_update_facing_from_dir(move_dir)
		velocity.x = move_dir * speed

	# --- JUMP (lockout: niente jump durante dash) ---
	if Input.is_action_just_pressed("jump") and not is_dashing:
		if is_on_floor():
			velocity.y = jump_force
			jump_pressed = true
			d("[Player] JUMP")
		elif is_on_wall() or _last_wall_normal != Vector2.ZERO:
			var wall_n := _get_wall_normal_for_jump()
			if wall_n == Vector2.ZERO:
				d("[Player] WALL JUMP blocked (no wall normal)")
			else:
				velocity.y = wall_jump_vertical
				velocity.x = wall_n.x * wall_jump_horizontal
				_try_update_facing_from_dir(wall_n.x)
				jump_pressed = true
				can_air_dash = true
				_last_wall_normal = Vector2.ZERO
				_last_wall_time = 0.0
				d("[Player] WALL JUMP normal=%s vel=%s" % [str(wall_n), str(velocity)])

	# --- ATTACK (hitbox via shape enable/disable) ---
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_start_attack_boomerang()

	_update_attack_boomerang(delta)
	_update_animation(move_dir, grounded, jump_pressed)

	move_and_slide()
	_cache_wall_normal()


func _try_update_facing_from_dir(dir: float) -> void:
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
	if sprite and sprite is Sprite2D:
		(sprite as Sprite2D).flip_h = (facing == -1)
	elif sprite and sprite is AnimatedSprite2D:
		(sprite as AnimatedSprite2D).flip_h = (facing == -1)

	_hitbox_base = _compute_hitbox_base_for_aim(aim_mode)
	if attack_hitbox_shape and not is_attacking:
		_set_hitbox_position(_hitbox_base)


func is_on_beat() -> bool:
	return beat_timer <= rhythm_window or beat_timer >= beat_interval - rhythm_window


func _update_animation(move_dir: float, grounded: bool, jump_pressed: bool) -> void:
	var spr := sprite as AnimatedSprite2D
	if not spr:
		return

	if is_attacking:
		_play_animation("attack", spr)
		return

	if jump_pressed or not grounded:
		_play_animation("jump", spr)
		return

	if abs(move_dir) > 0.1:
		_play_animation("run", spr)
	else:
		_play_animation("idle", spr)


func _play_animation(name: String, spr: AnimatedSprite2D) -> void:
	if not spr.sprite_frames:
		return
	if not spr.sprite_frames.has_animation(name):
		return
	if spr.animation != name or not spr.is_playing():
		spr.play(name)


func consume_feedback(amount: float) -> bool:
	var ok := feedback >= amount
	if ok:
		feedback -= amount
	return ok


# -----------------------------
# DAMAGE + I-FRAMES API
# -----------------------------
func take_damage(amount: int, from_global_pos: Vector2 = Vector2.ZERO) -> void:
	if _is_dead:
		return
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
	GameManager.play_damage()
	GameManager.flash_damage()
	if damage_shake_enabled:
		GameManager.screenshake(damage_shake_duration, damage_shake_strength)
	hp_changed.emit(hp, max_hp)

	if hp <= 0:
		_die()


func kill() -> void:
	# Usato per kill-zone (caduta)
	if _is_dead:
		return
	hp = 0
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
	if _is_dead:
		return
	_is_dead = true
	d("[Player] DEAD -> reload level")

	# Micro polish (hitstop e screenshake)
	if Engine.has_singleton("GameManager"):
		GameManager.hitstop(0.06, 0.05)
		GameManager.screenshake(0.12, 10.0)

	# Disabilita input/physics immediatamente
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)

	# pulizia stato
	is_dashing = false
	is_attacking = false
	dash_timer = 0.0
	dash_cd = 0.0
	# Usa set_deferred per evitare errori durante flush queries
	$AttackHitbox/CollisionShape2D.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	feedback = 0.0
	invuln_timer = 0.0
	_attack_active = false
	_attack_on_beat = false
	_aim_locked = false
	_boomerang_phase = 0
	_boomerang_t = 0.0
	pogo_used_this_attack = false
	aim_mode = AIM_FORWARD
	if hat_spin:
		hat_spin.visible = false
		hat_spin.stop()

	# attesa breve prima del reload (ignora time_scale)
	await get_tree().create_timer(respawn_delay, false, false, true).timeout

	# Reload del livello (non respawn)
	# In Godot 4, gli autoload sono accessibili direttamente come variabili globali
	if GameManager:
		# Il reload resetta tutto: HP, posizione, stato del livello
		await GameManager.reload_level(true, false)  # fade sì, title no
	else:
		push_error("[Player] GameManager non trovato per reload!")


# -----------------------------
# ATTACK / BOOMERANG
# -----------------------------
func _start_attack_boomerang() -> void:
	is_attacking = true
	_attack_active = false
	_attack_on_beat = is_on_beat()
	_attack_aim_at_start = aim_mode
	pogo_used_this_attack = false
	_boomerang_phase = 1
	_boomerang_t = 0.0
	_attack_windup_timer = max(attack_windup, 0.0)
	_aim_locked = true
	_hitbox_base = _compute_hitbox_base_for_aim(_attack_aim_at_start)
	_attack_dir = _get_attack_dir(_attack_aim_at_start)
	_attack_max_distance = _compute_attack_max_distance(_attack_dir, boomerang_distance)

	var total_lock := attack_windup + boomerang_out_time + boomerang_hold_time + boomerang_return_time + facing_lock_extra
	facing_lock_timer = total_lock

	if attack_hitbox and attack_hitbox.has_method("reset_for_new_attack"):
		attack_hitbox.reset_for_new_attack()
	attack_hitbox_shape.disabled = true
	_set_hitbox_position(_hitbox_base)

	d("[Player] ATTACK start on_beat=%s facing=%s aim=%s" % [str(_attack_on_beat), str(facing), _attack_aim_at_start])

	if _attack_on_beat:
		feedback = min(feedback + feedback_per_hit, feedback_max)
		GameManager.play_hit_on_beat()
	else:
		GameManager.play_miss()

	if _attack_windup_timer <= 0.0:
		_activate_attack_hitbox()


func _update_attack_boomerang(delta: float) -> void:
	if not is_attacking:
		return

	if not _attack_active:
		_attack_windup_timer -= delta
		if _attack_windup_timer > 0.0:
			return
		_activate_attack_hitbox()

	match _boomerang_phase:
		1:
			var dur: float = max(boomerang_out_time, 0.0001)
			_boomerang_t += delta
			var t: float = clamp(_boomerang_t / dur, 0.0, 1.0)
			var eased: float = _cubic_out(t)
			var offset: Vector2 = _hitbox_base + _attack_dir * _attack_max_distance * eased
			_set_hitbox_position(offset)
			if t >= 1.0:
				if boomerang_hold_time > 0.0:
					_boomerang_phase = 2
					_boomerang_t = 0.0
				else:
					_boomerang_phase = 3
					_boomerang_t = 0.0
		2:
			_boomerang_t += delta
			if _boomerang_t >= boomerang_hold_time:
				_boomerang_phase = 3
				_boomerang_t = 0.0
		3:
			var dur_ret: float = max(boomerang_return_time, 0.0001)
			_boomerang_t += delta
			var t_ret: float = clamp(_boomerang_t / dur_ret, 0.0, 1.0)
			var eased_in: float = _cubic_in(t_ret)
			var offset_ret: Vector2 = _hitbox_base + _attack_dir * _attack_max_distance * (1.0 - eased_in)
			_set_hitbox_position(offset_ret)
			if t_ret >= 1.0:
				_end_attack_boomerang()


func _end_attack_boomerang() -> void:
	_set_hitbox_position(_compute_hitbox_base_for_aim(aim_mode))
	attack_hitbox_shape.disabled = true
	is_attacking = false
	_attack_active = false
	_attack_windup_timer = 0.0
	_attack_on_beat = false
	_attack_aim_at_start = AIM_FORWARD
	_boomerang_phase = 0
	_boomerang_t = 0.0
	_aim_locked = false
	pogo_used_this_attack = false
	if is_on_floor():
		aim_mode = AIM_FORWARD
	elif Input.is_action_pressed("move_down"):
		aim_mode = AIM_DOWN
	else:
		aim_mode = AIM_FORWARD
	_apply_visual_and_hitbox()
	if hat_spin:
		hat_spin.visible = false
		hat_spin.stop()
	d("[Player] ATTACK end")

func _activate_attack_hitbox() -> void:
	if _attack_active:
		return
	_attack_active = true
	attack_hitbox_shape.disabled = false
	if hat_spin:
		hat_spin.visible = true
		hat_spin.play()


func _set_hitbox_position(pos: Vector2) -> void:
	if attack_hitbox_shape:
		attack_hitbox_shape.position = pos
	if hat_spin:
		hat_spin.position = pos


func _compute_hitbox_base_for_aim(aim: String) -> Vector2:
	if aim == AIM_DOWN:
		return Vector2(hitbox_offset_x_down * float(facing), hitbox_offset_y_down)
	if aim == AIM_UP:
		return Vector2(hitbox_offset_x_up * float(facing), hitbox_offset_y_up)
	return Vector2(hitbox_offset_x * float(facing), 0.0)


func _get_attack_dir(aim: String) -> Vector2:
	if aim == AIM_DOWN:
		return Vector2(0, 1)
	if aim == AIM_UP:
		return Vector2(0, -1)
	var dir := Vector2(float(facing), 0)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	return dir.normalized()


func _compute_attack_max_distance(dir: Vector2, base_distance: float) -> float:
	if dir == Vector2.ZERO:
		return base_distance
	var space := get_world_2d().direct_space_state
	var from := global_position
	var to := global_position + dir.normalized() * base_distance
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.exclude = [self, attack_hitbox, attack_hitbox_shape]
	params.collision_mask = get_collision_mask()
	var result := space.intersect_ray(params)
	if result.is_empty():
		return base_distance
	var hit_pos: Vector2 = result.position
	var dist := from.distance_to(hit_pos) - boomerang_wall_padding
	return max(0.0, min(base_distance, dist))


func _on_attack_hit(_target: Node) -> void:
	if not is_attacking:
		return
	if pogo_used_this_attack:
		return
	if is_on_floor():
		return
	if _attack_aim_at_start != AIM_DOWN:
		return
	if not _attack_on_beat:
		return
	velocity.y = pogo_velocity
	pogo_used_this_attack = true
	d("[Player] POGO!")


func _cubic_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3)


func _cubic_in(t: float) -> float:
	return pow(t, 3)


func _cache_wall_normal() -> void:
	if is_on_wall():
		var n := get_wall_normal()
		if n == Vector2.ZERO and get_slide_collision_count() > 0:
			var c := get_slide_collision(get_slide_collision_count() - 1)
			if c:
				n = c.get_normal()
		_last_wall_normal = n
		_last_wall_time = wall_jump_memory
	else:
		if _last_wall_time <= 0.0:
			_last_wall_normal = Vector2.ZERO


func _get_wall_normal_for_jump() -> Vector2:
	var n := _last_wall_normal
	if n == Vector2.ZERO:
		n = get_wall_normal()
		if n == Vector2.ZERO and get_slide_collision_count() > 0:
			var c := get_slide_collision(get_slide_collision_count() - 1)
			if c:
				n = c.get_normal()
	if n == Vector2.ZERO:
		return Vector2.ZERO
	return Vector2(sign(n.x) if n.x != 0 else 0, 0)


func is_attack_active() -> bool:
	return _attack_active


func is_on_beat_attack() -> bool:
	return _attack_on_beat
