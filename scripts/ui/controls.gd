extends Control

@onready var _action_button: Button = %ActionButton

var _player: Player

func _ready() -> void:
	add_to_group(&"controls")
	_action_button.pressed.connect(_on_action_pressed)

func bind_player(player: Player) -> void:
	_player = player

func _on_action_pressed() -> void:
	if _player != null:
		_player.interact()
