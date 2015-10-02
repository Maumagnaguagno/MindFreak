require 'test/unit'
require 'stringio'
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

  def test_interpreter_set_one
    # Clear first cell and add one
    program = SET_ONE.dup
    tape = [10]
    assert_equal(nil, MindFreak.setup(program, tape))
    assert_equal(SET_ONE, MindFreak.program)
    MindFreak.run_interpreter
    assert_equal([1], MindFreak.tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_interpreter_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_equal(nil, MindFreak.setup(program, tape))
    assert_equal('[->+<]', MindFreak.program)
    MindFreak.run_interpreter
    assert_equal([0, 15], MindFreak.tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_interpreter_io
    # Using StringIO to simulate output
    program = ',.,.,..,.>.'
    tape = [0, 33]
    input = StringIO.new('Helo','r')
    output = StringIO.new
    assert_equal(nil, MindFreak.setup(program, tape, true, input, output))
    MindFreak.run_interpreter
    assert_equal([111, 33], MindFreak.tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  #-----------------------------------------------
  # Bytecode
  #-----------------------------------------------

  def test_bytecode_set
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.make_bytecode(SET_ONE)
    assert_equal(
      [
        [MindFreak::JUMP,       2],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   0],
        [MindFreak::INCREMENT,  1]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, set]
    assert_equal(
      [
        [MindFreak::INCREMENT, 1, nil, true]
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end

  def test_bytecode_sum
    # Bytecode uses [instruction, argument]
    program = SUM.dup
    MindFreak.check_program(program)
    bytecode = MindFreak.make_bytecode(program)
    assert_equal(
      [
        [MindFreak::JUMP,       5],
        [MindFreak::INCREMENT, -1],
        [MindFreak::FORWARD,    1],
        [MindFreak::INCREMENT,  1],
        [MindFreak::FORWARD,   -1],
        [MindFreak::JUMPBACK,   0]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, set]
    assert_equal(
      [
        [MindFreak::JUMP,       5],
        [MindFreak::INCREMENT, -1],
        [MindFreak::INCREMENT,  1, 1, nil],
        [MindFreak::JUMPBACK,   0]
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end

  def test_bytecode_nullification
    # Add and subtract
    bytecode = MindFreak.make_bytecode('+++---')
    assert_equal([], bytecode)
    # Subtract and add
    bytecode = MindFreak.make_bytecode('---+++')
    assert_equal([], bytecode)
    # Add one
    bytecode = MindFreak.make_bytecode('---++++')
    assert_equal([[MindFreak::INCREMENT, 1]], bytecode)
    # Check if pairs are matched
    bytecode = MindFreak.make_bytecode('+>>-<>+<<-')
    assert_equal([], bytecode)
  end

  def test_bytecode_offset
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.make_bytecode('>+<<.>')
    assert_equal(
      [
        [MindFreak::FORWARD,   1],
        [MindFreak::INCREMENT, 1],
        [MindFreak::FORWARD,  -2],
        [MindFreak::WRITE,     1],
        [MindFreak::FORWARD,   1]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, set]
    assert_equal(
      [
        [MindFreak::INCREMENT, 1,  1, nil],
        [MindFreak::WRITE,     1, -1, nil],
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end
end