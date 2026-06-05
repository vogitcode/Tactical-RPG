## Abstract base for a single unit of execution within an action's effect pipeline.
## Subclass and override execute_async(ctx) to implement concrete behavior.
class_name BaseEffect
extends Resource

func execute_async(_ctx: ActionContext) -> void:
	pass
