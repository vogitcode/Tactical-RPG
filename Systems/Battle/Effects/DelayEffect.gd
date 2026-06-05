## Waits for a fixed duration — used to pace effect timing in the combat pipeline.
class_name DelayEffect
extends BaseEffect

@export var duration: float = 0.3

func _init(d: float = 0.3) -> void:
	duration = d

func execute_async(ctx: ActionContext) -> void:
	await ctx.unit.get_tree().create_timer(duration).timeout
