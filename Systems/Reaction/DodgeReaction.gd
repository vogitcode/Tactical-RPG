## Reaction for units that ended their turn — dodge incoming attacks.
## Trigger condition is temporary: reactor has spent all AP (simulates "ended turn").
## On win: attack misses + dodge icon shown briefly.
class_name DodgeReaction
extends BaseReaction

const ICON_PATH := "res://Assets/Icon/fb651.png"
const ICON_DURATION := 2.0
const ICON_OFFSET := Vector2(0, 24)

func _init() -> void:
	base_rp = 6

func can_trigger(action: CombatAction, reactor: Unit) -> bool:
	return action.action_id == &"attack" and reactor.action_points == 0

func execute_async(reactor: Unit) -> void:
	var texture := load(ICON_PATH) as Texture2D
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = ICON_OFFSET
	reactor.add_child(sprite)
	await reactor.get_tree().create_timer(ICON_DURATION).timeout
	sprite.queue_free()
