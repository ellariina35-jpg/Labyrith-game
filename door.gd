extends Area2D

var type: String = "empty"

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	input_pickable = true

func reset_visuals() -> void:
	sprite.texture = load("res://assets/generated/door_sprite_frame_0.png")
	sprite.scale = Vector2.ONE

func reveal_content() -> void:
	var path: String = "res://assets/generated/empty_icon_frame_0.png"
	
	match type:
		"monster":
			path = "res://assets/generated/monster_icon_frame_0.png"
		"chest":
			path = "res://assets/generated/chest_icon_frame_0.png"
		"empty":
			path = "res://assets/generated/empty_icon_frame_0.png"
		"exit":
			path = "res://assets/generated/exit_icon_frame_0.png"
	
	sprite.texture = load(path)
	sprite.scale = Vector2(0.1, 0.1)
	var tween = sprite.create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var main = get_parent()
		if main.has_method("move_player_to_door"):
			main.move_player_to_door(self)
