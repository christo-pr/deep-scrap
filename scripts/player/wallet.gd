class_name Wallet
extends Node

signal changed(coins: int)

var coins := 0

func add(amount: int) -> void:
	if not multiplayer.is_server() or amount <= 0:
		return
	_set_coins(coins + amount)

func spend(amount: int) -> bool:
	if not multiplayer.is_server() or amount <= 0 or coins < amount:
		return false
	_set_coins(coins - amount)
	return true

func apply_snapshot(value: int) -> void:
	_set_coins(value)

func _set_coins(value: int) -> void:
	value = maxi(value, 0)
	if value == coins:
		return
	coins = value
	changed.emit(coins)
