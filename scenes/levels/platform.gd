extends StaticBody2D

@export var required_feedback := 50.0
var player: CharacterBody2D = null

func _ready() -> void:
	player = get_parent().get_node("Player")

func _process(delta: float) -> void:
	if player != null and $Sprite != null:
		if player.feedback >= required_feedback:
			$Sprite.modulate.a = 1.0
		else:
			$Sprite.modulate.a = 0.0
