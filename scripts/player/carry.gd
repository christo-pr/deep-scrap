extends Node
class_name Carry

signal changed
signal place_requested(scene: PackedScene, at: Vector2)

const HANDS := 4

var data := CarryData.new()

func _ready() -> void:
	data.setup(HANDS)
	data.changed.connect(func() -> void: changed.emit())

func try_add(item: ItemData, count: int) -> int:
	return data.try_add(item, count)

func select_slot(index: int) -> void:
	data.select(index)

func use_selected() -> void:
	var slot := data.current()
	if slot == null or slot.item == null:
		return
	var player := get_parent() as Player
	if player == null:
		return
	match slot.item.use_kind:
		ItemData.UseKind.CONSUME:
			player.apply_grant(slot.item.grant_stat, slot.item.grant_amount)
			data.consume_one()
		ItemData.UseKind.PLACE:
			if slot.item.place_scene == null:
				return
			place_requested.emit(slot.item.place_scene, player.global_position)
			data.consume_one()
