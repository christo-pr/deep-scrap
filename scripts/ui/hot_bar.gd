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

func _ready() -> void:
	for child in _row.get_children():
		var slot := child as Button
		if slot == null:
			continue
		_slots.append(slot)
		slot.toggled.connect(_on_slot_toggled.bind(slot))
		_apply_scale(slot, slot.button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for i in SLOT_ACTIONS.size():
		if not event.is_action_pressed(SLOT_ACTIONS[i]):
			continue
		if i < _slots.size():
			_slots[i].button_pressed = not _slots[i].button_pressed
		get_viewport().set_input_as_handled()
		return

func _on_slot_toggled(toggled_on: bool, slot: Button) -> void:
	_apply_scale(slot, toggled_on)

func _apply_scale(slot: Button, selected: bool) -> void:
	var bounds = slot.custom_minimum_size
	slot.pivot_offset = bounds * 0.5
	slot.scale = SELECTED_SCALE if selected else Vector2.ONE
