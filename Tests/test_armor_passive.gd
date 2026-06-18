extends GutTest

var _unit: Unit
var _passive: ArmorPassive

func before_each() -> void:
	_unit = Unit.new()
	_unit.max_hp = 20
	add_child_autofree(_unit)
	_passive = ArmorPassive.new()
	_passive.armor_value = 2

# --- Passive logic in isolation ---

func test_reduces_damage_by_armor_value() -> void:
	var ctx := TakeDamageContext.new()
	ctx.unit = _unit
	ctx.original_amount = 10
	ctx.modified_damage = 10
	_passive.handle_hook(HookId.ON_TAKE_DAMAGE, ctx)
	assert_eq(ctx.modified_damage, 8)

func test_clamps_damage_to_zero() -> void:
	var ctx := TakeDamageContext.new()
	ctx.unit = _unit
	ctx.original_amount = 1
	ctx.modified_damage = 1
	_passive.handle_hook(HookId.ON_TAKE_DAMAGE, ctx)
	assert_eq(ctx.modified_damage, 0)

func test_wrong_context_type_is_noop() -> void:
	# Passive casts ctx → nếu sai type thì return sớm, context không bị chỉnh
	var ctx := DeathCheckContext.new()
	ctx.unit = _unit
	ctx.prevent_death = false
	_passive.handle_hook(HookId.ON_TAKE_DAMAGE, ctx)
	assert_false(ctx.prevent_death)

# --- Integration: qua Unit.take_damage() ---

func test_unit_takes_reduced_damage() -> void:
	_unit.add_passive(_passive)
	_unit.take_damage(10)
	assert_eq(_unit.current_hp, 12)  # 20 - (10 - 2) = 12
