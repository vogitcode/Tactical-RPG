## Base class for all player interaction state nodes.
## Subclasses override virtual methods to handle input relevant to their state.
## Emit transition_requested to request a state change — SM decides and executes it.
class_name PlayerInteractionState
extends Node

enum Phase { IDLE, MENU_OPEN, TARGETING }

signal transition_requested(from: PlayerInteractionState, to: Phase)

## Set in editor — used as key in SM's state dictionary.
@export var phase: Phase = Phase.IDLE

var _sm: PlayerInteractionStateMachine

func _ready() -> void:
	_sm = get_parent() as PlayerInteractionStateMachine

func enter() -> void: pass
func exit() -> void: pass

func on_unit_acting(_unit: Unit) -> void: pass
func on_tile_clicked(_pos: Vector2i) -> void: pass
func on_action_chosen(_action: BaseAction) -> void: pass
func on_menu_closed() -> void: pass
func on_cancel() -> void: pass
