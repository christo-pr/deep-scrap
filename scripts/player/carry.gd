extends Node
class_name Carry

signal changed

const HANDS := 4

var data := CarryData.new()

func _ready() -> void:
	data.setup(HANDS)
	data.changed.connect(func() -> void: changed.emit())

func try_add(item: ItemData, count: int) -> int:
	return data.try_add(item, count)

func select_slot(index: int) -> void:
	data.select(index)

func throw_selected() -> void:
	var player := get_parent() as Player
	if player == null or not player.is_multiplayer_authority():
		return
	var sea := get_tree().current_scene
	if sea != null and sea.has_method(&"request_throw"):
		sea.request_throw(data.selected)

func use_selected() -> void:
	var player := get_parent() as Player
	if player == null or not player.is_multiplayer_authority():
		return
	var sea := get_tree().current_scene
	if sea != null and sea.has_method(&"request_use"):
		sea.request_use(data.selected)
