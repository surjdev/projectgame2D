extends Control

# This variable keeps track of which item is currently selected.
var selected_index = 0

# These arrays will store our item slot and blood splatter nodes.
var item_slots = []
var blood_splatters = []

func _ready():
	# Get references to the item slots and their blood splatter children.
	var flashlight_slot = get_node("ItemSlots/Flashlight")
	var knife_slot = get_node("ItemSlots/Knife")
	
	# Append the nodes to their respective arrays.
	item_slots.append(flashlight_slot)
	item_slots.append(knife_slot)
	
	blood_splatters.append(flashlight_slot.get_node("BloodSplatterFL"))
	blood_splatters.append(knife_slot.get_node("BloodSplatterK"))
	
	# Hide all blood splatters initially.
	for splatter in blood_splatters:
		splatter.visible = false
	
	# Select the first item by default.
	select_item(selected_index)

func _input(event):
	# Listen for your custom input actions.
	if event.is_action_pressed("inventory_slot_1"):
		select_item(0)
	elif event.is_action_pressed("inventory_slot_2"):
		select_item(1)

func select_item(index):
	# Ensure the index is a valid number for our list of items.
	if index < 0 or index >= item_slots.size():
		return
	
	# Hide the blood splatter of the previously selected item.
	if selected_index < blood_splatters.size():
		blood_splatters[selected_index].visible = false
	
	# Show the blood splatter of the newly selected item.
	if index < blood_splatters.size():
		blood_splatters[index].visible = true
	
	# Update the selected_index to the new item's index.
	selected_index = index
