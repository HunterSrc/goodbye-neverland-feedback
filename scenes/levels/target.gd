extends Area2D

func _ready() -> void:
	# collegamento corretto
	self.area_entered.connect(Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	print("COLPITO da ", area.name)
