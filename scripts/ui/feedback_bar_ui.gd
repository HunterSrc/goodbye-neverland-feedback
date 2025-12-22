extends Control

# FeedbackBar UI: mostra la barra del feedback del player
# Con animazioni smooth e indicatore on-beat

@export var bar_width: float = 200.0
@export var bar_height: float = 20.0
@export var smooth_speed: float = 8.0  # velocità del lerp

@export var outline_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var bar_color_full: Color = Color(0.2, 0.8, 1.0, 1.0)  # Azzurro/cyan
@export var bar_color_empty: Color = Color(0.3, 0.3, 0.3, 0.5)  # Grigio
@export var beat_indicator_color: Color = Color(1.0, 1.0, 0.3, 0.8)  # Giallo

@export var beat_indicator_size: float = 4.0
@export var beat_indicator_pulse_scale: float = 1.5
@export var show_value_label: bool = true
@export var value_label_prefix: String = "FEEDBACK"
@export var high_charge_color: Color = Color(0.3, 1.0, 1.0, 1.0)
@export var low_charge_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var tick_count: int = 5  # tacche interne (es. ogni 20 se max=100)
@export var tick_color: Color = Color(1.0, 1.0, 1.0, 0.2)
@export var tick_width: float = 2.0
@export var tick_height: float = 16.0

var current_feedback: float = 0.0
var max_feedback: float = 100.0
var target_feedback: float = 0.0

var is_on_beat: bool = false
var beat_indicator_alpha: float = 0.0

@onready var bar_outline: ColorRect = $BarOutline
@onready var bar_bg: ColorRect = $BarBackground
@onready var bar_fill: ColorRect = $BarFill
@onready var beat_indicator: ColorRect = $BeatIndicator
@onready var value_label: Label = $ValueLabel
@onready var ticks_container: Control = $Ticks


func _ready() -> void:
	# Setup iniziale
	custom_minimum_size = Vector2(bar_width, bar_height)
	size = Vector2(bar_width, bar_height)
	
	# Background (già impostato nella scena, ma assicuriamoci)
	if bar_outline:
		bar_outline.color = outline_color

	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_bg.color = background_color
	
	# Fill bar
	bar_fill.color = bar_color_full
	bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar_fill.offset_right = 0.0
	
	# Beat indicator (sulla destra della barra)
	beat_indicator.color = beat_indicator_color
	beat_indicator.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	beat_indicator.offset_left = bar_width
	beat_indicator.offset_right = bar_width + beat_indicator_size
	beat_indicator.offset_top = -beat_indicator_size * 0.5
	beat_indicator.offset_bottom = bar_height + beat_indicator_size * 0.5

	# Label valore
	if value_label:
		value_label.visible = show_value_label
	
	_build_ticks()


func _process(delta: float) -> void:
	# Aggiorna feedback dal player
	var player = GameManager.get_player()
	if player:
		target_feedback = player.feedback
		max_feedback = player.feedback_max
		is_on_beat = player.is_on_beat()
	else:
		target_feedback = 0.0
		is_on_beat = false
	
	# Smooth lerp della barra
	current_feedback = lerp(current_feedback, target_feedback, smooth_speed * delta)
	
	# Aggiorna la larghezza della barra fill
	var fill_ratio = clamp(current_feedback / max_feedback, 0.0, 1.0)
	bar_fill.offset_right = -bar_width * (1.0 - fill_ratio)
	bar_fill.color = low_charge_color.lerp(high_charge_color, fill_ratio)
	
	# Aggiorna indicatore on-beat
	if is_on_beat:
		beat_indicator_alpha = lerp(beat_indicator_alpha, 1.0, 15.0 * delta)
		# Pulse effect
		var pulse = sin(Time.get_ticks_msec() / 50.0) * 0.3 + 1.0
		beat_indicator.scale.y = pulse * beat_indicator_pulse_scale
	else:
		beat_indicator_alpha = lerp(beat_indicator_alpha, 0.0, 10.0 * delta)
		beat_indicator.scale.y = lerp(beat_indicator.scale.y, 1.0, 10.0 * delta)
	
	beat_indicator.modulate.a = beat_indicator_alpha

	# Aggiorna label quantitativo
	if value_label and show_value_label:
		var val := int(round(current_feedback))
		var max_val := int(round(max_feedback))
		value_label.text = "%s %d / %d" % [value_label_prefix, val, max_val]


func _build_ticks() -> void:
	if ticks_container == null:
		return

	for c in ticks_container.get_children():
		c.queue_free()

	var usable_width := bar_width
	var usable_height := bar_height

	for i in range(1, tick_count):
		var frac := float(i) / float(tick_count)
		var x := usable_width * frac - tick_width * 0.5

		var tick := ColorRect.new()
		tick.color = tick_color
		tick.size = Vector2(tick_width, tick_height)
		tick.position = Vector2(x, (usable_height - tick_height) * 0.5)
		ticks_container.add_child(tick)
