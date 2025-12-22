extends Area2D

@export var death_height: float = 0.0
@export var debug_enabled: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("kill"):
		body.kill()
	elif body.has_method("take_damage"):
		body.take_damage(999, global_position)
	if debug_enabled:
		print("[KillZone] player entered -> death")
