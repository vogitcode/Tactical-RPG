class_name Unit
extends Node2D

signal hp_changed(old_hp: int, new_hp: int)
signal unit_died()
signal grid_position_changed(new_pos: Vector2i)

var unit_data: UnitData

@export var unit_name: String = "Unit"
@export var team: int = 0           # 0 = player, 1 = enemy
@export var max_hp: int = 20
@export var max_action_points: int = 2
@export var move_points: int = 4
@export var attack_range: int = 1
@export var attack_damage: int = 5

# Turn state — reset each turn
var action_points: int = 0
var has_moved: bool = false
var has_acted: bool = false
var has_waited: bool = false

# Persistent state
var current_hp: int = 0
var grid_position: Vector2i = Vector2i.ZERO

var _sprite: Sprite2D
var _status_receiver: StatusEffectReceiver
var _hook_index: Dictionary = {}
var _runtime_passives: Array[BasePassive] = []
var _capabilities: Dictionary = {}  # Blackboard: StringName → Variant

func _ready() -> void:
	current_hp = max_hp
	action_points = max_action_points
	add_to_group("units")
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_status_receiver = StatusEffectReceiver.new()
	add_child(_status_receiver)
	if unit_data != null:
		_runtime_passives.assign(unit_data.passives)
	_rebuild_hook_index()
	for passive in _runtime_passives:
		var ctx := AttachContext.new()
		ctx.unit = self
		passive.handle_hook(HookId.ON_PASSIVE_ATTACHED, ctx)

func get_status_receiver() -> StatusEffectReceiver:
	return _status_receiver

func set_sprite_texture(texture: Texture2D) -> void:
	_sprite.texture = texture

func set_sprite_atlas(texture: Texture2D, region: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	_sprite.texture = atlas

# --- Grid position ---

func set_grid_position(pos: Vector2i) -> void:
	grid_position = pos
	grid_position_changed.emit(pos)

# --- Turn state ---

func reset_turn() -> void:
	action_points = max_action_points
	has_moved = false
	has_acted = false
	has_waited = false
	_status_receiver.tick_and_expire(self)

# --- Actions ---

func get_available_actions() -> Array[BaseAction]:
	var all: Array[BaseAction] = _build_action_list()
	var available: Array[BaseAction] = []
	for action in all:
		if action.can_execute(self):
			available.append(action)
	var extra_ctx := AvailableActionsContext.new()
	extra_ctx.unit = self
	fire_hook(HookId.GET_AVAILABLE_ACTIONS, extra_ctx)
	available.append_array(extra_ctx.extra_actions)
	return available

func _build_action_list() -> Array[BaseAction]:
	if unit_data == null or unit_data.actions.is_empty():
		return []
	var result: Array[BaseAction] = []
	result.assign(unit_data.actions)
	return result

func get_reactions() -> Array[BaseReaction]:
	if unit_data == null:
		return []
	var result: Array[BaseReaction] = []
	result.assign(unit_data.reactions)
	return result

# --- HP / damage ---

func take_damage(amount: int) -> void:
	var actual := amount
	if has_status("guarding"):
		actual = max(1, amount / 2)

	var damage_ctx := TakeDamageContext.new()
	damage_ctx.original_amount = amount
	damage_ctx.modified_damage = actual
	damage_ctx.unit = self
	fire_hook(HookId.ON_TAKE_DAMAGE, damage_ctx)
	actual = maxi(0, damage_ctx.modified_damage)

	var old_hp := current_hp
	current_hp = max(0, current_hp - actual)
	hp_changed.emit(old_hp, current_hp)

	if current_hp == 0:
		var death_ctx := DeathCheckContext.new()
		death_ctx.unit = self
		fire_hook(HookId.ON_DEATH_CHECK, death_ctx)
		if death_ctx.prevent_death:
			current_hp = 1
			hp_changed.emit(0, 1)
			return
		unit_died.emit()
		_on_death()

func heal(amount: int) -> void:
	var old_hp := current_hp
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(old_hp, current_hp)

func is_alive() -> bool:
	return current_hp > 0

# --- Status effects ---

func apply_status(status_id: StringName, turns: int = 1) -> void:
	var effect := StatusEffect.new()
	effect.status_id = status_id
	effect.duration = turns
	_status_receiver.apply(effect)

func has_status(status_id: StringName) -> bool:
	return _status_receiver.has_effect(status_id)

func remove_status(status_id: StringName) -> void:
	_status_receiver.remove_effect(status_id)

func _on_death() -> void:
	if is_instance_valid(_sprite):
		_sprite.modulate = Color(0.4, 0.4, 0.4, 0.6)
	modulate = Color(0.5, 0.5, 0.5, 0.7)

# --- Passive hook registry ---

func _rebuild_hook_index() -> void:
	_hook_index.clear()
	for passive in _runtime_passives:
		for hook_id: StringName in passive.get_hook_ids():
			if not _hook_index.has(hook_id):
				_hook_index[hook_id] = []
			_hook_index[hook_id].append(passive)

func get_runtime_passives() -> Array[BasePassive]:
	return _runtime_passives

func add_passive(passive: BasePassive) -> void:
	_runtime_passives.append(passive)
	_rebuild_hook_index()
	var ctx := AttachContext.new()
	ctx.unit = self
	passive.handle_hook(HookId.ON_PASSIVE_ATTACHED, ctx)

func remove_passive(passive: BasePassive) -> void:
	var ctx := DetachContext.new()
	ctx.unit = self
	passive.handle_hook(HookId.ON_PASSIVE_DETACHED, ctx)
	_runtime_passives.erase(passive)
	_rebuild_hook_index()

# --- Blackboard (dynamic capability bag) ---

func set_capability(key: StringName, value: Variant) -> void:
	_capabilities[key] = value

func has_capability(key: StringName) -> bool:
	return _capabilities.has(key)

func get_capability(key: StringName, default: Variant = null) -> Variant:
	return _capabilities.get(key, default)

func remove_capability(key: StringName) -> void:
	_capabilities.erase(key)

func fire_hook(hook_id: StringName, ctx: PassiveContext) -> void:
	for passive in _hook_index.get(hook_id, []):
		(passive as BasePassive).handle_hook(hook_id, ctx)

func get_effective_move_points() -> int:
	var ctx := MoveQueryContext.new()
	ctx.unit = self
	fire_hook(HookId.GET_MOVE_POINTS, ctx)
	return move_points + ctx.bonus_move_points

func get_effective_attack_range(base: int) -> int:
	var ctx := AttackRangeQueryContext.new()
	fire_hook(HookId.GET_ATTACK_RANGE, ctx)
	return base + ctx.bonus_range

## Shows the icon of every passive registered for hook_id above the unit.
## Call this at the moment the hook's effect actually matters (e.g. move execution).
func show_active_hook_icons(hook_id: StringName) -> void:
	for passive in _hook_index.get(hook_id, []):
		_show_passive_activation(passive as BasePassive)

func _show_passive_activation(passive: BasePassive) -> void:
	if passive == null or passive.icon == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = passive.icon
	sprite.position = Vector2(0, -40)
	add_child(sprite)
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", -64.0, 0.8)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.8)
	tween.tween_callback(sprite.queue_free)
