extends StaticBody2D

@export var fall_delay: float = 1.2
@export var respawn: bool = false
@export var respawn_time: float = 3.0
@export var debug_enabled: bool = false

@onready var shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var visual: CanvasItem = get_node_or_null("Visual")

var _falling: bool = false
var _original_pos: Vector2


func d(msg: String) -> void:
	if debug_enabled:
		print("[FallingPlatform] " + msg)


func _ready() -> void:
	_original_pos = global_position
	var detector: Area2D = get_node_or_null("Detector") as Area2D
	if detector:
		detector.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _falling:
		return
	if not body.is_in_group("player"):
		return

	_falling = true
	await get_tree().create_timer(fall_delay).timeout

	_set_active(false)

	if respawn:
		await get_tree().create_timer(respawn_time).timeout
		_reset_platform()
	else:
		queue_free()


func _set_active(enabled: bool) -> void:
	if shape:
		shape.set_deferred("disabled", not enabled)
	collision_layer = 2 if enabled else 0
	collision_mask = 0 if not enabled else collision_mask
	if visual:
		visual.modulate = Color(0.8, 0.8, 0.8, 1.0) if enabled else Color(0.8, 0.8, 0.8, 0.3)


func _reset_platform() -> void:
	_falling = false
	global_position = _original_pos
	_set_active(true)
