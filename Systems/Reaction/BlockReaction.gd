## Reaction for units with Guard status — blocks incoming attacks.
## Triggers when the reactor is guarding and the incoming action is an attack.
## On win: damage is blocked (handled by BattleProcessor not calling execute) + shield icon shown.
class_name BlockReaction
extends BaseReaction

const ICON_PATH := "res://Assets/Icon/fb664.png"
const ICON_DURATION := 3.0
const ICON_OFFSET := Vector2(0, 24)

func _init() -> void:
	base_rp = 8

func can_trigger(action: CombatAction, reactor: Unit) -> bool:
	return action.action_id == &"attack" and reactor.has_status("guarding")

func execute_async(reactor: Unit) -> void:
	var texture := load(ICON_PATH) as Texture2D
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = ICON_OFFSET
	reactor.add_child(sprite)
	await reactor.get_tree().create_timer(ICON_DURATION).timeout
	sprite.queue_free()
