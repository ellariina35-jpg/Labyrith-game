extends Node2D

@onready var player_entity: CharacterBody2D = $Player
@onready var message_label: Label = $CanvasLayer/HUD/MessageLabel
@onready var doors: Array = [$Path1, $Path2, $Path3]
@onready var start_panel: Panel = $CanvasLayer/HUD/StartPanel
@onready var game_over_panel: Panel = $CanvasLayer/HUD/GameOverPanel
@onready var health_label: Label = $CanvasLayer/HUD/HealthLabel
@onready var combat_panel: Panel = $CanvasLayer/HUD/CombatPanel
@onready var battle_label: Label = $CanvasLayer/HUD/CombatPanel/BattleLabel
@onready var monster_label: Label = $CanvasLayer/HUD/CombatPanel/MonsterLabel
@onready var roll_label: Label = $CanvasLayer/HUD/CombatPanel/RollLabel
@onready var attack_button: Button = $CanvasLayer/HUD/CombatPanel/AttackButton
@onready var room_panel: Panel = $CanvasLayer/HUD/RoomPanel
@onready var room_background: TextureRect = $CanvasLayer/HUD/RoomPanel/RoomBackground
@onready var room_description: Label = $CanvasLayer/HUD/RoomPanel/RoomDescription
@onready var leave_button: Button = $CanvasLayer/HUD/RoomPanel/LeaveButton

var empty_doors_count: int = 0
var is_game_over: bool = false
var game_started: bool = false
var monster_health: int = 0
var is_player_turn: bool = true
var is_moving: bool = false
var current_door_type: String = ""

func _ready() -> void:
	start_panel.visible = true
	game_over_panel.visible = false
	combat_panel.visible = false
	room_panel.visible = false
	if player_entity:
		player_entity.set_physics_process(false)
	
	if not attack_button.pressed.is_connected(_on_attack_button_pressed):
		attack_button.pressed.connect(_on_attack_button_pressed)
	
	if not leave_button.pressed.is_connected(_on_leave_button_pressed):
		leave_button.pressed.connect(_on_leave_button_pressed)
	
	room_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_background.anchor_right = 1.0
	room_background.anchor_bottom = 0.8
	
	room_description.anchor_top = 0.8
	room_description.anchor_right = 1.0
	room_description.anchor_bottom = 0.9
	room_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	leave_button.anchor_top = 0.9
	leave_button.anchor_left = 0.4
	leave_button.anchor_right = 0.6
	leave_button.anchor_bottom = 1.0
	
	var start_button: Button = start_panel.get_node("StartButton")
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
		
	var restart_button: Button = game_over_panel.get_node("RestartButton")
	if not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	update_ui()
	message_label.text = "Welcome to the Labyrinth"

func start_new_game() -> void:
	empty_doors_count = 0
	is_game_over = false
	game_started = true
	is_moving = false
	current_door_type = ""
	start_panel.visible = false
	game_over_panel.visible = false
	combat_panel.visible = false
	room_panel.visible = false
	
	if player_entity:
		player_entity.set_physics_process(true)
		player_entity.health = 10
		player_entity.has_shield = false
		player_entity.has_double_attack = false
		reset_player()
	
	randomize_doors()
	update_ui()
	message_label.text = "Choose a door!"

func _on_start_button_pressed() -> void:
	start_new_game()

func _on_restart_button_pressed() -> void:
	start_new_game()

func randomize_doors() -> void:
	var type_options: Array[String] = ["monster", "chest", "empty"]
	type_options.shuffle()
	
	for i in range(doors.size()):
		var d = doors[i]
		d.type = str(type_options[i])
		if d.has_method("reset_visuals"):
			d.reset_visuals()

func move_player_to_door(door: Area2D) -> void:
	if is_game_over or not game_started or is_moving:
		return
	is_moving = true
	var tween = create_tween()
	tween.tween_property(player_entity, "global_position", door.global_position, 0.5)
	await tween.finished
	if door.has_method("reveal_content"):
		door.reveal_content()
	await get_tree().create_timer(0.6).timeout
	_on_door_entered(door)

func _on_door_entered(door: Area2D) -> void:
	if is_game_over or not game_started:
		return
		
	current_door_type = door.type
	show_room(door.type)

func show_room(type: String) -> void:
	is_moving = true
	room_panel.visible = true
	match type:
		"monster":
			room_background.texture = preload("res://assets/generated/dungeon_monster_room_frame_0.png")
			room_description.text = "A fearsome monster blocks your path!"
			leave_button.text = "Fight!"
		"chest":
			room_background.texture = preload("res://assets/generated/dungeon_chest_room_frame_0.png")
			room_description.text = "You found a mysterious chest!"
			leave_button.text = "Open Chest"
		"empty":
			room_background.texture = preload("res://assets/generated/dungeon_empty_room_frame_0.png")
			room_description.text = "An empty room... but you feel closer to the exit."
			if empty_doors_count + 1 >= 4:
				leave_button.text = "Proceed to Exit"
			else:
				leave_button.text = "Leave Room"
		"exit":
			room_background.texture = preload("res://assets/generated/dungeon_exit_open_frame_0.png")
			room_description.text = "Freedom awaits!"
			leave_button.text = "ESCAPE!"

func _on_leave_button_pressed() -> void:
	room_panel.visible = false
	match current_door_type:
		"monster":
			start_combat()
		"chest":
			apply_treasure()
			finish_turn()
		"empty":
			empty_doors_count += 1
			if empty_doors_count >= 4:
				current_door_type = "victory"
				show_room("exit")
			else:
				message_label.text = "An empty door! You are closer to the exit..."
				finish_turn()
		"victory":
			trigger_game_over(true)

func finish_turn() -> void:
	reset_player()
	is_moving = false
	randomize_doors()
	update_ui()

func apply_treasure() -> void:
	var roll: int = randi() % 4
	if player_entity:
		match roll:
			0:
				player_entity.health += 2
				message_label.text = "Found a Health Potion! +2 HP"
			1:
				player_entity.health += 5
				message_label.text = "Found a Great Health Potion! +5 HP"
			2:
				player_entity.has_shield = true
				message_label.text = "Found a Shield! Next attack negated."
			3:
				player_entity.has_double_attack = true
				message_label.text = "Found an Attack Buff! Next attack x2."
	update_ui()

func start_combat() -> void:
	if player_entity:
		player_entity.set_physics_process(false)
	monster_health = (randi() % 5) + 5
	is_player_turn = true
	battle_label.text = "Monster! Let's battle!"
	monster_label.text = "Monster Health: " + str(monster_health)
	roll_label.text = "It is your turn to roll!"
	attack_button.text = "Roll the dice? (Yes)"
	attack_button.disabled = false
	combat_panel.visible = true

func _on_attack_button_pressed() -> void:
	if is_player_turn:
		player_attack()
	else:
		monster_attack()

func player_attack() -> void:
	attack_button.disabled = true
	var player_roll: int = (randi() % 6) + 1
	var player_damage: int = player_roll
	
	if player_entity and player_entity.has_double_attack:
		player_damage *= 2
		player_entity.has_double_attack = false
	
	monster_health -= player_damage
	monster_label.text = "Monster Health: " + str(max(0, monster_health))
	roll_label.text = "You rolled a " + str(player_roll) + "! Dealt " + str(player_damage) + " damage."
	
	await get_tree().create_timer(1.5).timeout
	
	if monster_health <= 0:
		roll_label.text = "Monster defeated!"
		await get_tree().create_timer(1.0).timeout
		attack_button.disabled = false
		combat_panel.visible = false
		if player_entity:
			player_entity.set_physics_process(true)
			reset_player()
		is_moving = false
		randomize_doors()
		update_ui()
		message_label.text = "Monster defeated! Choose another door."
	else:
		is_player_turn = false
		battle_label.text = "Monster's turn to roll..."
		attack_button.text = "Continue?"
		attack_button.disabled = false

func monster_attack() -> void:
	attack_button.disabled = true
	var monster_roll: int = (randi() % 6) + 1
	var monster_damage: int = monster_roll
	
	if player_entity:
		if player_entity.has_shield:
			monster_damage = 0
			player_entity.has_shield = false
			roll_label.text = "Monster rolled " + str(monster_roll) + ". SHIELD BLOCKED!"
		else:
			player_entity.health -= monster_damage
			roll_label.text = "Monster rolled " + str(monster_roll) + ". You took " + str(monster_damage) + " damage!"
	
	update_ui()
	await get_tree().create_timer(1.5).timeout
	
	if player_entity and player_entity.health <= 0:
		combat_panel.visible = false
		trigger_game_over(false)
	else:
		is_player_turn = true
		battle_label.text = "It is your turn to roll!"
		attack_button.text = "Roll the dice? (Yes)"
		attack_button.disabled = false

func update_ui() -> void:
	if player_entity:
		health_label.text = "Health: " + str(player_entity.health)
		if player_entity.has_shield:
			health_label.text += " [SHIELD]"
		if player_entity.has_double_attack:
			health_label.text += " [ATK x2]"

func reset_player() -> void:
	if player_entity:
		player_entity.velocity = Vector2.ZERO
		player_entity.position = Vector2(576, 500)

func trigger_game_over(win: bool) -> void:
	is_game_over = true
	game_started = false
	is_moving = false
	if player_entity:
		player_entity.set_physics_process(false)
	game_over_panel.visible = true
	var game_over_label: Label = game_over_panel.get_node("GameOverLabel")
	if win:
		game_over_label.text = "YOU ESCAPED!"
	else:
		game_over_label.text = "GAME OVER"
