## Screen-space UI manager — owns ActionMenu and other fixed HUD elements.
## Does NOT know about gameplay systems.
## All signal wiring between gameplay and UI is handled by the Compositor (Demo.gd).
class_name ScreenUIManager
extends Node

@onready var action_menu: ActionMenu = $ActionMenu
