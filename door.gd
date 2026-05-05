extends Area2D

signal door_entered(type: String)

enum DoorType { MONSTER, CHEST, EMPTY }
var type: DoorType = DoorType.EMPTY

@onready var sprite: Sprite2D = $Sprite2D

func set_type(new_type: DoorType) -> void:
	type = new_type

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		var type_str: String = ""
		match type:
			DoorType.MONSTER: type_str = "monster"
			DoorType.CHEST: type_str = "chest"
			DoorType.EMPTY: type_str = "empty"
		door_entered.emit(type_str)
