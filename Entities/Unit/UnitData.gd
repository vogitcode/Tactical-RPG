## Data Resource for a unit type — stats, sprite, and starting action list.
## Create one .tres per unit type (Knight, Rogue, Bandit, …) in the editor.
## UnitManager reads this when spawning; Unit._build_action_list() reads actions from here.
class_name UnitData
extends Resource

@export var unit_name: String = "Unit"
@export var max_hp: int = 20
@export var max_action_points: int = 2
@export var move_points: int = 4
@export var attack_range: int = 1
@export var attack_damage: int = 5
@export var atlas_cell: Vector2i = Vector2i(0, 0)
@export var actions: Array[BaseAction] = []
@export var reactions: Array[BaseReaction] = []
@export var passives: Array[BasePassive] = []
