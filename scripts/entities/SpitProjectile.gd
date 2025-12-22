extends Area2D

@export var speed: float = 220.0
@export var lifetime: float = 3.0
@export var damage_amount: int = 1
@export var debug_enabled: bool = false

var direction: Vector2 = Vector2.RIGHT


func d(msg: String) -> void:
	if debug_enabled:
		print("[Spit] " + msg)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(func(): queue_free())


func setup(dir: Vector2, new_speed: float, new_damage: int) -> void:
	direction = dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	speed = new_speed
	damage_amount = new_damage


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount, global_position)
		queue_free()
	elif body is TileMap or body is StaticBody2D:
		queue_free()
