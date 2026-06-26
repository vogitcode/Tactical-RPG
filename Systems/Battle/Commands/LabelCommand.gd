## Shows a floating text label above the target unit.
## Placeholder — FloatingTextManager integration not yet implemented.
class_name LabelCommand
extends BaseCommand

@export var text: String = ""

func _init(t: String = "") -> void:
	text = t

func execute_async(_ctx: BaseContext) -> void:
	pass
