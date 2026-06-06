extends GutTest

var _arbitrator: Arbitrator
var _source_unit: Unit
var _reactor_unit: Unit

func before_each() -> void:
	_arbitrator = Arbitrator.new()
	add_child_autofree(_arbitrator)

	_source_unit = Unit.new()
	add_child_autofree(_source_unit)

	_reactor_unit = Unit.new()
	add_child_autofree(_reactor_unit)

# --- NullReaction: initiator wins unconditionally, không cần RP ---

func test_null_reaction_initiator_wins_unconditionally() -> void:
	var action := AttackAction.new()
	action.base_rp = 1  # thấp nhất có thể — không được dùng
	var result := _arbitrator.resolve(action, _source_unit, NullReaction.new(), _reactor_unit)
	assert_true(result.initiator_hit())
	assert_false(result.reactor_hit())

# --- Deterministic: higher RP wins ---

func test_initiator_higher_rp_wins() -> void:
	var action := AttackAction.new()
	action.base_rp = 10
	var reaction := BaseReaction.new()
	reaction.base_rp = 5
	var result := _arbitrator.resolve(action, _source_unit, reaction, _reactor_unit)
	assert_true(result.initiator_hit())
	assert_false(result.reactor_hit())

func test_reactor_higher_rp_wins() -> void:
	var action := AttackAction.new()
	action.base_rp = 5
	var reaction := BaseReaction.new()
	reaction.base_rp = 10
	var result := _arbitrator.resolve(action, _source_unit, reaction, _reactor_unit)
	assert_false(result.initiator_hit())
	assert_true(result.reactor_hit())

func test_equal_rp_both_partial() -> void:
	var action := AttackAction.new()
	action.base_rp = 10
	var reaction := BaseReaction.new()
	reaction.base_rp = 10
	var result := _arbitrator.resolve(action, _source_unit, reaction, _reactor_unit)
	assert_true(result.initiator_hit())
	assert_true(result.reactor_hit())
