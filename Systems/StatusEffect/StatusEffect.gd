## Base class for all status effects. Extend to add custom turn-start or on-expire behavior.
## Store instances in StatusEffectReceiver on each Unit.
class_name StatusEffect
extends Resource

@export var status_id: StringName = &""
@export var duration: int = 1

func tick() -> void:
	duration -= 1

func is_expired() -> bool:
	return duration <= 0

func on_turn_start(_unit: Unit) -> void:
	pass

func on_expire(_unit: Unit) -> void:
	pass
