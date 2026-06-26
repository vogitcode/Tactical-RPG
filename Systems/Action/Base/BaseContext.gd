## Base context for all effect execution pipelines.
## Carries the minimum shared contract: who is affected and which grid is active.
## Domain-specific subclasses (ActionContext, TileContext) extend this.
class_name BaseContext
extends RefCounted

var target_unit: Unit = null
var grid_system: GridSystem = null
