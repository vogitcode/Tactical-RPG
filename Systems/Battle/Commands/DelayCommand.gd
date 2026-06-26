## Waits for a fixed duration — used to pace effect timing in the combat pipeline.
class_name DelayCommand
extends BaseCommand

@export var duration: float = 0.3

func _init(d: float = 0.3) -> void:
	duration = d

func execute_async(_ctx: BaseContext) -> void:
	var ctx := _ctx as ActionContext
	if ctx == null or ctx.source_unit == null:
		return
	await ctx.source_unit.get_tree().create_timer(duration).timeout
