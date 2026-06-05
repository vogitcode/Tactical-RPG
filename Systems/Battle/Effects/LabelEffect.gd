## Shows a floating text label above the target unit.
## Placeholder — FloatingTextManager integration not yet implemented.
class_name LabelEffect
extends BaseEffect

@export var text: String = ""

func _init(t: String = "") -> void:
	text = t

func execute_async(_ctx: ActionContext) -> void:
	pass
