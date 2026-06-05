## Abstract base for per-faction AI decision logic.
## Subclasses override decide() to implement faction behavior.
## Brain does NOT know about other factions — it only receives AIContext.
class_name FactionAIBrain
extends Node

@export var faction_id: int = -1

func decide(_unit: Unit, _ctx: AIContext) -> BaseAction:
	return null
