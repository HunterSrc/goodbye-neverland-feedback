extends Node2D

@export var feedback_cost: float = 20.0
@export var active_time: float = 3.0
@export var cooldown_time: float = 0.2
@export var debug_enabled: bool = false
@export var flash_time: float = 0.18

var _is_active: bool = false
var _cooling: bool = false

@onready var solid: StaticBody2D = get_node_or_null("Solid")
@onready var shape: CollisionShape2D = get_node_or_null("Solid/CollisionShape2D")
@onready var detector: Area2D = get_node_or_null("Detector")
@onready var visual: CanvasItem = get_node_or_null("Visual")
@onready var flash: ColorRect = get_node_or_null("Flash") as ColorRect
@onready var cost_label: Label = get_node_or_null("CostLabel") as Label


func d(msg: String) -> void:
	if debug_enabled:
		print("[FeedbackPlatform] " + msg)


func _ready() -> void:
	if detector:
		detector.body_entered.connect(_on_body_entered)
	if cost_label:
		cost_label.text = str(int(feedback_cost))
	_set_active(false, true)


func _on_body_entered(body: Node2D) -> void:
	if _is_active or _cooling:
		return
	if not body.is_in_group("player"):
		return

	var player := body
	if not player.has_method("consume_feedback"):
		return

	if player.consume_feedback(feedback_cost):
		d("Feedback consumed: %s" % feedback_cost)
		_activate_temporarily()
	else:
		d("Not enough feedback (need %s)" % feedback_cost)


func _activate_temporarily() -> void:
	_set_active(true)
	_flash()
	await get_tree().create_timer(active_time).timeout
	_set_active(false)
	_cooling = true
	await get_tree().create_timer(cooldown_time).timeout
	_cooling = false


func _set_active(enabled: bool, force: bool = false) -> void:
	if not force and _is_active == enabled:
		return

	_is_active = enabled

	if shape:
		shape.set_deferred("disabled", not enabled)
	if solid:
		solid.set_deferred("collision_layer", 2 if enabled else 0)  # use same world layer as ground
		solid.set_deferred("collision_mask", 0)

	if visual:
		visual.modulate = Color(0.7, 1.0, 0.8, 1.0) if enabled else Color(0.6, 0.6, 0.6, 0.5)
	if cost_label:
		cost_label.visible = not enabled
		cost_label.modulate.a = 1.0 if not enabled else 0.2


func _flash() -> void:
	if flash == null:
		return
	flash.visible = true
	flash.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(flash, "modulate:a", flash.color.a, flash_time * 0.5)
	t.tween_property(flash, "modulate:a", 0.0, flash_time * 0.5)
	t.finished.connect(func():
		if flash:
			flash.visible = false)
