## Shared configuration resource for the grid system.
## Assign in Inspector or create via code. One instance shared across
## GridData, TopDownGridAdapter, and GridVisualizer — single source of truth.
class_name GridConfig
extends Resource

@export var grid_width: int = 12
@export var grid_height: int = 10
@export var cell_size: Vector2i = Vector2i(32, 32)
## World-space offset of the grid's top-left corner.
@export var cell_offset: Vector2 = Vector2.ZERO
