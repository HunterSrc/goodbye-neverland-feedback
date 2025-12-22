extends Control

@export var main_scene: PackedScene

@onready var new_game_button: Button = $CenterContainer/VBoxContainer/NewGameButton
@onready var load_button: Button = $CenterContainer/VBoxContainer/LoadButton


func _ready() -> void:
	if main_scene == null:
		main_scene = load("res://scenes/Main.tscn")

	new_game_button.pressed.connect(_on_new_game)
	load_button.pressed.connect(_on_load)

	new_game_button.grab_focus()


func _on_new_game() -> void:
	if main_scene:
		get_tree().change_scene_to_packed(main_scene)


func _on_load() -> void:
	print("menu carica")
