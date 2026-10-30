class_name CarryData
extends Resource

var slots: Array[CarrySlot] = []
var selected: int = 0

func setup(size: int) -> void:
	slots.clear()
	for _i in size:
		slots.append(CarrySlot.new())

func select(index: int) -> void:
	if index < 0 or index >= slots.size() or index == selected:
		return
	selected = index
	changed.emit()

func current() -> CarrySlot:
	if slots.is_empty():
		return null
	return slots[selected]

func try_add(item: ItemData, count: int) -> int:
	if item == null or count <= 0:
		return count
	var left := count
	if item.max_stack > 1:
		for slot in slots:
			if left <= 0:
				break
			if slot.item == null or slot.item.id != item.id:
				continue
			var room := item.max_stack - slot.count
			if room <= 0:
				continue
			var moved := mini(room, left)
			slot.count += moved
			left -= moved
	for slot in slots:
		if left <= 0:
			break
		if slot.item != null:
			continue
		var moved := mini(item.max_stack, left)
		slot.item = item
		slot.count = moved
		left -= moved
	if left != count:
		changed.emit()
	return left

func consume_one() -> void:
	var slot := current()
	if slot == null or slot.item == null:
		return
	slot.count -= 1
	if slot.count <= 0:
		slot.item = null
		slot.count = 0
	changed.emit()

func take_selected() -> CarrySlot:
	var slot := current()
	if slot == null or slot.item == null or slot.count <= 0:
		return null
	var taken := CarrySlot.new()
	taken.item = slot.item
	taken.count = slot.count
	slot.item = null
	slot.count = 0
	changed.emit()
	return taken
