extends Control

@onready var _health_bar: ProgressBar = $Bars/HealthBar
@onready var _air_bar: ProgressBar = $Bars/AirBar
@onready var _coins_label: Label = $Bars/CoinsLabel

var _player: Player

func _ready() -> void:
	add_to_group(&"status_bars")

func bind_player(player: Player) -> void:
	if _player != null:
		_player.health_changed.disconnect(_on_health_changed)
		_player.air_changed.disconnect(_on_air_changed)
		_player.wallet.changed.disconnect(_on_coins_changed)
	_player = player
	_player.health_changed.connect(_on_health_changed)
	_player.air_changed.connect(_on_air_changed)
	_player.wallet.changed.connect(_on_coins_changed)
	_on_health_changed(_player.health, _player.health_max)
	_on_air_changed(_player.air, _player.air_max)
	_on_coins_changed(_player.wallet.coins)

func _on_health_changed(value: float, max_value: float) -> void:
	_health_bar.max_value = max_value
	_health_bar.value = value

func _on_air_changed(value: float, max_value: float) -> void:
	_air_bar.max_value = max_value
	_air_bar.value = value

func _on_coins_changed(coins: int) -> void:
	_coins_label.text = "%d coins" % coins
