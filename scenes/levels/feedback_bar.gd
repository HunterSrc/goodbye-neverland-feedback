extends ColorRect

var player: Node = null
var max_width := 200.0 # larghezza massima della barra

func _ready() -> void:
	player = get_tree().get_current_scene().get_node("Player")

func _process(delta: float) -> void:
	if player != null:
		# calcola larghezza proporzionale al feedback
		size.x = lerp(size.x, (player.feedback / player.feedback_max) * max_width, 0.1)
