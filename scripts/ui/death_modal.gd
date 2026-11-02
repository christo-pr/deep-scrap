extends Control

const SHOW_DELAY := 1.0

@onready var _revive_button: Button = %ReviveButton

var _player: Player

func _ready() -> void:
	add_to_group(&"death_modal")
	hide()
	_revive_button.pressed.connect(_on_revive_pressed)

func bind_player(player: Player) -> void:
	if _player != null:
		_player.died.disconnect(_on_died)
		_player.revived.disconnect(_on_revived)
	_player = player
	_player.died.connect(_on_died)
	_player.revived.connect(_on_revived)

func _on_died() -> void:
	await get_tree().create_timer(SHOW_DELAY).timeout
	if _player == null or not _player.net_dead:
		return
	show()
	_revive_button.grab_focus()

func _on_revived() -> void:
	hide()

func _on_revive_pressed() -> void:
	var sea := get_tree().current_scene
	if sea != null and sea.has_method(&"request_revive"):
		sea.request_revive()
