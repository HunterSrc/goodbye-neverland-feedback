extends Control

@export var prefix: String = "NOISE:"
@export var show_only_when_present: bool = true

@onready var label: Label = $Label


func _ready() -> void:
	_update_text()


func _process(_delta: float) -> void:
	_update_text()


func _update_text() -> void:
	if not Engine.has_singleton("GameManager"):
		return
	var progress := GameManager.get_noise_progress()
	var destroyed: int = progress.get("destroyed", 0)
	var total: int = progress.get("total", 0)

	if show_only_when_present and total == 0:
		visible = false
		return

	visible = true
	label.text = "%s %d / %d" % [prefix, destroyed, total]
