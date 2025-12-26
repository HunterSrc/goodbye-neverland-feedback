extends CharacterBody2D

# Bulwark: mini-boss gatekeeper. Slow movement, timed slam attack.

@export var move_speed: float = 60.0
@export var detection_range: float = 260.0
@export var slam_interval: float = 2.0
@export var slam_windup: float = 0.45
@export var slam_duration: float = 0.22
@export var damage_amount: int = 1
@export var min_hits_to_die: int = 4
@export var max_hits_to_die: int = 6
@export var feedback_threshold: float = 40.0  # vulnerability if feedback >= this when off-beat
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 900.0
@export var debug_enabled: bool = false

var hits_remaining: int = 1
var _slam_timer: float = 0.0
var _windup_active: bool = false
var _slam_active: bool = false
var _player: CharacterBody2D = null
var _attack_area: Area2D
var _slam_area: Area2D


func d(msg: String) -> void:
	if debug_enabled:
		print("[Bulwark] " + msg)


func _ready() -> void:
	hits_remaining = randi_range(min_hits_to_die, max_hits_to_die)
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_attack_area = get_node_or_null("HitArea")
	_slam_area = get_node_or_null("SlamArea")

	if _attack_area:
		_attack_area.area_entered.connect(_on_hit_area_area_entered)
	else:
		push_warning("[Bulwark] HitArea non trovata")

	if _slam_area:
		_slam_area.body_entered.connect(_on_slam_area_body_entered)
		_slam_area.monitoring = false
	else:
		push_warning("[Bulwark] SlamArea non trovata")

	d("Ready. hits=%d" % hits_remaining)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	var grounded := is_on_floor()

	# Basic slow drift toward player on ground
	if _player and not _windup_active:
		var dir := sign(_player.global_position.x - global_position.x)
		velocity.x = dir * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)

	# Gravity
	if not grounded:
		velocity.y = clamp(velocity.y + gravity * delta, -max_fall_speed, max_fall_speed)
	else:
		velocity.y = max(velocity.y, 0.0)

	# Slam timing
	_slam_timer += delta
	if not _windup_active and not _slam_active:
		var in_range := _player and _player.is_inside_tree() and global_position.distance_to(_player.global_position) <= detection_range
		if in_range and _slam_timer >= slam_interval:
			_start_windup()

	if _windup_active:
		_slam_timer += delta
		if _slam_timer >= slam_windup:
			_start_slam()

	if _slam_active:
		if _slam_timer >= slam_windup + slam_duration:
			_end_slam()

	move_and_slide()


func _start_windup() -> void:
	_windup_active = true
	_slam_timer = 0.0
	velocity.x = 0.0
	d("Windup")


func _start_slam() -> void:
	_slam_active = true
	_windup_active = false
	if _slam_area:
		_slam_area.monitoring = true
	GameManager.hitstop(0.03, 0.08)
	GameManager.screenshake(0.08, 4.5)
	d("Slam!")


func _end_slam() -> void:
	_slam_active = false
	_slam_timer = 0.0
	if _slam_area:
		_slam_area.monitoring = false
	d("Slam end")


func _on_slam_area_body_entered(body: Node) -> void:
	if not _slam_active:
		return
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage_amount, global_position)


func _on_hit_area_area_entered(area: Area2D) -> void:
	if not area.has_method("is_attack_active"):
		return
	if not area.is_attack_active():
		return

	var on_beat := area.has_method("is_on_beat_attack") and area.is_on_beat_attack()
	var player_fb_ok := false
	var attacker := area.get_parent()
	if attacker and attacker.is_in_group("player"):
		# best-effort: read feedback property if available
		if attacker.has_method("get") and attacker.has_method("set"):
			var fb_val = attacker.get("feedback")
			if typeof(fb_val) in [TYPE_INT, TYPE_FLOAT]:
				player_fb_ok = float(fb_val) >= feedback_threshold
		elif "feedback" in attacker:
			player_fb_ok = float(attacker.feedback) >= feedback_threshold

	if not on_beat and not player_fb_ok:
		d("Hit ignored (off-beat and feedback low)")
		return

	hits_remaining -= 1
	d("Bulwark hit! remaining=%d on_beat=%s fb_ok=%s" % [hits_remaining, str(on_beat), str(player_fb_ok)])
	GameManager.hitstop(0.05, 0.08)
	GameManager.screenshake(0.10, 6.0)
	if hits_remaining <= 0:
		queue_free()
