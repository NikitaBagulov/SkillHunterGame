# event_bus.gd
extends Node

signal boss_activated(boss: Boss)
signal boss_deactivated(boss: Boss)
signal boss_hp_updated(boss: Boss, current_hp: int, max_hp: int)

signal quick_slots_updated
signal quick_slot_selected(index: int)
