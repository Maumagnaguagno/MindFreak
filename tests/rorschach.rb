require 'test/unit'
require './MindFreak'

class Rorschach < Test::Unit::TestCase

  SET_ONE = '[-]+'
  SUM = '[->+<] Subtract one from first cell; add to the second; repeat until first cell is zero'

  def test_attributes
    [:program, :tape, :pointer, :debug, :debug=].each {|att| assert_respond_to(MindFreak, att)}
  end

  #-----------------------------------------------
  # Setup
  #-----------------------------------------------

  def test_setup
    # Start with no program or tape
    assert_equal(nil, MindFreak.setup(nil, nil, false))
    assert_equal(nil, MindFreak.program)
    assert_equal(nil, MindFreak.tape)
    # Setup
    program = ''
    tape = []
    assert_equal(nil, MindFreak.setup(program, tape))
    # Assert they are the same objects
    assert_same(program, MindFreak.program)
    assert_same(tape, MindFreak.tape)
  end

  def test_setup_no_check
    # Jumping over check is possible
    program = '[-['
    assert_equal(nil, MindFreak.setup(program, [], false))
    assert_equal(program, MindFreak.program)
  end

  def test_setup_check_control_open_bracket_exception
    # Expected to raise an exception
    program = '[-['
    assert_raises(RuntimeError) {assert_equal(nil, MindFreak.setup(program, []))}
    assert_same(program, MindFreak.program)
  end

  def test_setup_check_control_close_bracket_exception
    # Expected to raise an exception
    program = '[-]]'
    assert_raises(RuntimeError) {assert_equal(nil, MindFreak.setup(program, []))}
    assert_same(program, MindFreak.program)
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def test_set_first_cell
    # Clear first cell and add one
    program = SET_ONE.dup
    tape = [10]
    assert_equal(nil, MindFreak.setup(program, tape))
    assert_equal(SET_ONE, MindFreak.program)
    MindFreak.run_interpreter
    assert_equal([1], MindFreak.tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_sum_two_values_on_tape
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_equal(nil, MindFreak.setup(program, tape))
    assert_equal('[->+<]', MindFreak.program)
    MindFreak.run_interpreter
    assert_equal([0, 15], MindFreak.tape)
    assert_equal(0, MindFreak.pointer)
  end
end