extends Control

const SLOT_ACTIONS: Array[StringName] = [
	&"slot_1",
	&"slot_2",
	&"slot_3",
	&"slot_4",
]
const SELECTED_SCALE := Vector2(1.2, 1.2)

@onready var _row: HBoxContainer = $Bar/Row

var _slots: Array[Button] = []
var _player: Player

func _ready() -> void:
	add_to_group(&"hotbar")
	for child in _row.get_children():
		var slot := child as Button
		if slot == null:
			continue
		_slots.append(slot)
		slot.toggled.connect(_on_slot_toggled.bind(slot))
	_show_selected(0)

func bind_player(player: Player) -> void:
	if _player != null:
		_player.carry.changed.disconnect(_refresh)
	_player = player
	_player.carry.changed.connect(_refresh)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if _player == null or event.is_echo():
		return
	for i in SLOT_ACTIONS.size():
		if not event.is_action_pressed(SLOT_ACTIONS[i]):
			continue
		if i < _slots.size():
			_player.carry.select_slot(i)
			_slots[i].button_pressed = true
			_show_selected(i)
		get_viewport().set_input_as_handled()
		return

func _on_slot_toggled(toggled_on: bool, slot: Button) -> void:
	var index := _slots.find(slot)
	_apply_scale(slot, toggled_on)
	if toggled_on and _player != null and index >= 0:
		_player.carry.select_slot(index)

func _refresh() -> void:
	if _player == null:
		return
	var hands := _player.carry.data.slots
	for i in _slots.size():
		var button := _slots[i]
		var stack := hands[i]
		var item := stack.item
		button.icon = item.icon if item != null else null
		var count_label := button.get_node_or_null("Count") as Label
		if count_label == null:
			continue
		count_label.text = str(stack.count) if item != null and stack.count > 1 else ""
	_show_selected(_player.carry.data.selected)

func _show_selected(index: int) -> void:
	for i in _slots.size():
		_apply_scale(_slots[i], i == index)

func _apply_scale(slot: Button, selected: bool) -> void:
	var bounds := slot.size
	if bounds.x <= 0.0 or bounds.y <= 0.0:
		bounds = slot.custom_minimum_size
	slot.pivot_offset = bounds * 0.5
	slot.scale = SELECTED_SCALE if selected else Vector2.ONE
