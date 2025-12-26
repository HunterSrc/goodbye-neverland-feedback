extends Node2D

@export var fire_interval: float = 1.6
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 220.0
@export var aim_at_player: bool = true
@export var fixed_direction: Vector2 = Vector2.RIGHT
@export var fire_directions: Array[Vector2] = []
@export var damage: int = 1
@export var projectile_lifetime: float = 3.0
@export_range(0, 16, 1) var projectile_pool_size: int = 6
@export var muzzle_flash_time: float = 0.12
@export var muzzle_flash_scale: float = 1.4
@export var debug_enabled: bool = false
@export var min_hits_to_die: int = 2
@export var max_hits_to_die: int = 4

@onready var muzzle: Node2D = get_node_or_null("Muzzle")
@onready var muzzle_flash: CanvasItem = get_node_or_null("MuzzleFlash")
@onready var hit_area: Area2D = get_node_or_null("HitArea")

var _player: Node2D
var _timer: Timer
var hits_remaining: int = 1
var _projectile_pool: Array[Area2D] = []


func d(msg: String) -> void:
	if debug_enabled:
		print("[Spitter] " + msg)


func _ready() -> void:
	_player = GameManager.get_player() as Node2D
	hits_remaining = randi_range(min_hits_to_die, max_hits_to_die)

	_timer = Timer.new()
	_timer.wait_time = fire_interval
	_timer.one_shot = false
	_timer.autostart = true
	add_child(_timer)
	_timer.timeout.connect(_on_fire)

	if projectile_scene == null:
		projectile_scene = load("res://scenes/entities/SpitProjectile.tscn")

	if hit_area:
		hit_area.area_entered.connect(_on_hit_area_area_entered)

	_prewarm_pool()


func _physics_process(_delta: float) -> void:
	# Rinfresca il riferimento al player in caso di reload livello
	var p := GameManager.get_player() as Node2D
	if p and p != _player:
		_player = p


func _on_fire() -> void:
	if projectile_scene == null:
		return

	var dirs: Array[Vector2] = []

	if aim_at_player and _player and _player.is_inside_tree():
		var aim_dir := (_player.global_position - global_position).normalized()
		if aim_dir != Vector2.ZERO:
			dirs.append(aim_dir)
		else:
			dirs.append(fixed_direction.normalized())
	elif fire_directions.size() > 0:
		for v in fire_directions:
			if v != Vector2.ZERO:
				dirs.append(v.normalized())
	else:
		dirs.append(fixed_direction.normalized())

	for dir in dirs:
		var proj: Area2D = _get_projectile()
		if proj.get_parent() != get_tree().current_scene:
			if proj.get_parent():
				proj.get_parent().remove_child(proj)
			get_tree().current_scene.add_child(proj)
		if proj is Node2D:
			var spawn_pos := global_position
			if muzzle:
				spawn_pos = muzzle.global_position
			(proj as Node2D).global_position = spawn_pos
		if proj and proj.has_method("setup"):
			proj.setup(dir, projectile_speed, damage, projectile_lifetime)
		if proj and proj.has_method("activate"):
			proj.activate()
		d("Fire dir=%s speed=%.1f" % [str(dir), projectile_speed])

	_flash_muzzle()


func _on_hit_area_area_entered(area: Area2D) -> void:
	if not area.has_method("is_attack_active"):
		return
	if not area.is_attack_active():
		return

	hits_remaining -= 1
	d("Spitter hit! remaining=%d" % hits_remaining)
	GameManager.hitstop(0.04, 0.05)
	GameManager.screenshake(0.08, 4.0)
	if hits_remaining <= 0:
		queue_free()


func _prewarm_pool() -> void:
	for i in range(projectile_pool_size):
		_projectile_pool.append(_create_projectile())


func _create_projectile() -> Area2D:
	var proj := projectile_scene.instantiate()
	if proj and proj.has_signal("returned") and not proj.returned.is_connected(_on_projectile_returned):
		proj.returned.connect(_on_projectile_returned)
	add_child(proj)
	return proj as Area2D


func _get_projectile() -> Area2D:
	if _projectile_pool.size() > 0:
		return _projectile_pool.pop_back()
	return _create_projectile()


func _on_projectile_returned(proj: Area2D) -> void:
	if not is_instance_valid(proj):
		return
	if proj.monitoring:
		proj.set_deferred("monitoring", false)
	call_deferred("_park_projectile", proj)


func _park_projectile(proj: Area2D) -> void:
	if not is_instance_valid(proj):
		return
	if proj.monitoring:
		# Se è ancora in monitoring, riprova nel prossimo frame
		proj.set_deferred("monitoring", false)
		call_deferred("_park_projectile", proj)
		return
	if proj.get_parent() != self:
		if proj.get_parent():
			proj.get_parent().remove_child(proj)
		add_child(proj)
	if _projectile_pool.size() < projectile_pool_size:
		_projectile_pool.append(proj)

func _flash_muzzle() -> void:
	if muzzle_flash == null:
		return

	muzzle_flash.visible = true
	muzzle_flash.modulate.a = 1.0
	muzzle_flash.scale = Vector2.ONE * muzzle_flash_scale

	var t := create_tween()
	t.tween_property(muzzle_flash, "scale", Vector2.ONE, muzzle_flash_time)
	t.tween_property(muzzle_flash, "modulate:a", 0.0, muzzle_flash_time)
	t.finished.connect(func():
		if muzzle_flash:
			muzzle_flash.visible = false
	)
