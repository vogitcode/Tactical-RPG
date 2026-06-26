## Abstract base — a single executable unit of domain logic within a pipeline.
## Subclass and override execute_async(ctx) to implement concrete behavior.
class_name BaseCommand
extends Resource

func execute_async(_ctx: BaseContext) -> void:
	pass
