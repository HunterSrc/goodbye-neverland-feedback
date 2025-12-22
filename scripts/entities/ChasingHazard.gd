extends CharacterBody2D

@export var patrol_distance: float = 120.0
@export var patrol_speed: float = 80.0
@export var chase_speed: float = 140.0
@export var detection_radius: float = 200.0
@export var damage_amount: int = 1
@export var pause_time: float = 0.4
@export var debug_enabled: bool = false
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 900.0
@export var min_hits_to_die: int = 2
@export var max_hits_to_die: int = 4

var _origin: Vector2
var _dir: int = 1
var _pause_timer: float = 0.0
var _player: Node2D = null
var hits_remaining: int = 1


func d(msg: String) -> void:
	if debug_enabled:
		print("[ChasingHazard] " + msg)


func _ready() -> void:
	_origin = global_position
	_player = GameManager.get_player() as Node2D
	hits_remaining = randi_range(min_hits_to_die, max_hits_to_die)
	if has_node("Hitbox"):
		$Hitbox.body_entered.connect(_on_hitbox_body_entered)
		$Hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	# Refresh player after reload
	var p := GameManager.get_player() as Node2D
	if p and p != _player:
		_player = p

	if _pause_timer > 0.0:
		_pause_timer -= delta
		velocity.x = 0.0
	else:
		var speed := patrol_speed
		var target_dir := Vector2(_dir, 0.0)

		# Chase if player in range
		if _player and _player.is_inside_tree():
			var to_player := _player.global_position - global_position
			if to_player.length() <= detection_radius:
				speed = chase_speed
				target_dir = to_player.normalized()
				if debug_enabled:
					d("Chasing player dir=%s" % str(target_dir))

		# Patrol bounds
		if abs(global_position.x - _origin.x) >= patrol_distance and speed == patrol_speed:
			_dir *= -1
			target_dir = Vector2(_dir, 0.0)
			_pause_timer = pause_time

		velocity.x = target_dir.x * speed

	# Gravity
	if not is_on_floor():
		velocity.y = clamp(velocity.y + gravity * delta, -max_fall_speed, max_fall_speed)
	else:
		velocity.y = max(velocity.y, 0.0)

	move_and_slide()

	# Contact damage on slide collisions
	for i in range(get_slide_collision_count()):
		var c := get_slide_collision(i)
		if c and c.get_collider() and c.get_collider().is_in_group("player"):
			if c.get_collider().has_method("take_damage"):
				c.get_collider().take_damage(damage_amount, global_position)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not area.has_method("is_attack_active"):
		return
	if not area.is_attack_active():
		return

	hits_remaining -= 1
	d("Chaser hit! remaining=%d" % hits_remaining)
	GameManager.hitstop(0.04, 0.05)
	GameManager.screenshake(0.08, 4.0)
	if hits_remaining <= 0:
		queue_free()


func _on_hitbox_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage_amount, global_position)
