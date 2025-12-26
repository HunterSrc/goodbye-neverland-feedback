extends Area2D

@export var speed: float = 220.0
@export var lifetime: float = 3.0
@export var damage_amount: int = 1
@export var debug_enabled: bool = false

signal returned(projectile: Node)

var direction: Vector2 = Vector2.RIGHT
var _timer: Timer
var _active: bool = false
var _pending_life: float = 0.0


func d(msg: String) -> void:
	if debug_enabled:
		print("[Spit] " + msg)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.autostart = false
	add_child(_timer)
	_timer.timeout.connect(_despawn)
	_deactivate()


func setup(dir: Vector2, new_speed: float, new_damage: int, life: float = -1.0) -> void:
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	speed = new_speed
	damage_amount = new_damage
	_pending_life = lifetime if life <= 0.0 else life


func activate() -> void:
	var life_to_use := _pending_life if _pending_life > 0.0 else lifetime
	_activate(life_to_use)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount, global_position)
		_despawn()
	elif body is TileMap or body is StaticBody2D:
		_despawn()


func _activate(life: float) -> void:
	_active = true
	visible = true
	monitoring = true
	set_physics_process(true)
	_timer.start(life)


func _despawn() -> void:
	if not _active:
		return
	_timer.stop()
	_deactivate()
	returned.emit(self)
	# Se nessuno è connesso, liberiamo comunque
	if get_signal_connection_list("returned").is_empty():
		queue_free()


func _deactivate() -> void:
	_active = false
	visible = false
	set_deferred("monitoring", false)
	set_physics_process(false)
	direction = Vector2.RIGHT
