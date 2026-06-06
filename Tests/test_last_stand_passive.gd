extends GutTest

var _unit: Unit
var _passive: LastStandPassive

func before_each() -> void:
	_unit = Unit.new()
	_unit.max_hp = 20
	add_child_autofree(_unit)
	_passive = LastStandPassive.new()
	_unit.add_passive(_passive)

# --- Passive logic in isolation ---

func test_sets_prevent_death_true() -> void:
	var ctx := DeathCheckContext.new()
	ctx.unit = _unit
	ctx.prevent_death = false
	_passive.handle_hook(&"on_death_check", ctx)
	assert_true(ctx.prevent_death)

func test_removes_itself_from_unit_after_firing() -> void:
	var ctx := DeathCheckContext.new()
	ctx.unit = _unit
	ctx.prevent_death = false
	_passive.handle_hook(&"on_death_check", ctx)

	# Passive đã gọi remove_passive(self) — hook index đã được rebuild
	# Bắn hook lần 2 qua unit: nếu passive còn đó sẽ set prevent_death=true
	var ctx2 := DeathCheckContext.new()
	ctx2.unit = _unit
	ctx2.prevent_death = false
	_unit.fire_hook(&"on_death_check", ctx2)
	assert_false(ctx2.prevent_death)

# --- Integration: qua Unit.take_damage() ---

func test_unit_survives_lethal_damage_at_1hp() -> void:
	_unit.take_damage(100)
	assert_eq(_unit.current_hp, 1)
	assert_true(_unit.is_alive())

func test_passive_expires_after_one_use() -> void:
	_unit.take_damage(100)  # survive → current_hp = 1, passive removed
	_unit.take_damage(100)  # no passive → unit dies
	assert_false(_unit.is_alive())
