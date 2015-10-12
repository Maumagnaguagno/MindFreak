require 'test/unit'
require 'stringio'
require './MindFreak'

class Rorschach < Test::Unit::TestCase

  SET_ONE = '[-]+'
  SUM = '[->+<] Subtract one from first cell; add to the second; repeat until first cell is zero'

  def test_attributes
    [:pointer, :input, :input=, :output, :output=, :debug, :debug=].each {|att| assert_respond_to(MindFreak, att)}
  end

  #-----------------------------------------------
  # Check program
  #-----------------------------------------------

  def test_check_program_empty
    # Expected to raise an exception
    program = ''
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal('', program)
  end

  def test_check_program_comment_removal
    # Expected to raise an exception
    program = "abc<>[]--++#,.()123_-=;\n"
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal('<>[]--++,.-', program)
  end

  def test_check_program_open_bracket_exception
    # Expected to raise an exception
    assert_raises(RuntimeError) {MindFreak.check_program('[-[')}
  end

  def test_check_program_close_bracket_exception
    # Expected to raise an exception
    assert_raises(RuntimeError) {MindFreak.check_program('[-]]')}
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def test_run_interpreter_set_one
    # Clear first cell and add one
    program = SET_ONE.dup
    tape = [10]
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal(SET_ONE, program)
    MindFreak.run_interpreter(program, tape)
    assert_equal([1], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_interpreter_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal('[->+<]', program)
    MindFreak.run_interpreter(program, tape)
    assert_equal([0, 15], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_interpreter_io
    # Using StringIO to simulate output
    program = ',.,.,..,.>.'
    tape = [0, 33]
    MindFreak.input = StringIO.new('Helo','r')
    MindFreak.output = StringIO.new
    assert_equal(nil, MindFreak.check_program(program))
    MindFreak.run_interpreter(program, tape)
    assert_equal([111, 33], tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('Helo', MindFreak.input.string)
    assert_equal('Hello!', MindFreak.output.string)
  end

  #-----------------------------------------------
  # Run bytecode
  #-----------------------------------------------

  def test_run_bytecode_set_one
    # Clear first cell and add one
    program = SET_ONE.dup
    tape = [10]
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal(SET_ONE, program)
    MindFreak.run_bytecode(program, tape)
    assert_equal([1], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal('[->+<]', program)
    MindFreak.run_bytecode(program, tape)
    assert_equal([0, 15], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode_io
    # Using StringIO to simulate output
    program = ',.,.,..,.>.'
    tape = [0, 33]
    MindFreak.input = StringIO.new('Helo','r')
    MindFreak.output = StringIO.new
    assert_equal(nil, MindFreak.check_program(program))
    MindFreak.run_bytecode(program, tape)
    assert_equal([111, 33], tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('Helo', MindFreak.input.string)
    assert_equal('Hello!', MindFreak.output.string)
  end

  #-----------------------------------------------
  # Run bytecode2
  #-----------------------------------------------

  def test_run_bytecode2_set_one
    # Clear first cell and add one
    program = SET_ONE.dup
    tape = [10]
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal(SET_ONE, program)
    MindFreak.run_bytecode2(program, tape)
    assert_equal([1], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode2_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal('[->+<]', program)
    MindFreak.run_bytecode2(program, tape)
    assert_equal([0, 15], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode2_io
    # Using StringIO to simulate output
    program = ',.,.,..,.>.'
    tape = [0, 33]
    MindFreak.input = StringIO.new('Helo','r')
    MindFreak.output = StringIO.new
    assert_equal(nil, MindFreak.check_program(program))
    MindFreak.run_bytecode2(program, tape)
    assert_equal([111, 33], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('Helo', MindFreak.input.string)
    assert_equal('Hello!', MindFreak.output.string)
  end

  #-----------------------------------------------
  # Eval Ruby
  #-----------------------------------------------

  def test_eval_ruby_set_one
    # Clear first cell and add one
    program = SET_ONE.dup
    tape = [10]
    # Ruby evaluation mode requires local pointer
    pointer = 0
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal(SET_ONE, program)
    eval(MindFreak.to_ruby(program, tape, true))
    assert_equal([1], tape)
    assert_equal(0, pointer)
  end

  def test_eval_ruby_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    # Ruby evaluation mode requires local pointer
    pointer = 0
    assert_equal(nil, MindFreak.check_program(program))
    assert_equal('[->+<]', program)
    eval(MindFreak.to_ruby(program, tape, true))
    assert_equal([0, 15], tape)
    assert_equal(0, pointer)
  end

  def test_eval_ruby_io
    # Using StringIO to simulate output
    input = StringIO.new('Helo','r')
    output = StringIO.new
    program = ',.,.,..,.>.'
    tape = [0, 33]
    # Ruby evaluation mode requires local pointer
    pointer = 0
    assert_equal(nil, MindFreak.check_program(program))
    # Connect input and output local variables
    eval(MindFreak.to_ruby(program, tape, true, 'input', 'output'))
    assert_equal([111, 33], tape)
    assert_equal(0, pointer)
    assert_equal('Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  #-----------------------------------------------
  # to Ruby
  #-----------------------------------------------

  def test_to_ruby_set_one
    program = SET_ONE.dup
    assert_equal(nil, MindFreak.check_program(program))
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0\ntape[pointer] = 1",
      MindFreak.to_ruby(program, [])
    )
    # Array tape
    assert_equal(
      "tape = Array.new(1,0)\npointer = 0\ntape[pointer] = 1",
      MindFreak.to_ruby(program, [0])
    )
  end

  def test_to_ruby_sum
    program = SUM.dup
    assert_equal(nil, MindFreak.check_program(program))
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0\ntape[pointer+1] += tape[pointer]\ntape[pointer] = 0",
      MindFreak.to_ruby(program, [])
    )
    # Array tape
    assert_equal(
      "tape = Array.new(1,0)\npointer = 0\ntape[pointer+1] += tape[pointer]\ntape[pointer] = 0",
      MindFreak.to_ruby(program, [0])
    )
  end

  #-----------------------------------------------
  # to C
  #-----------------------------------------------

  def test_to_c_set_one
    program = SET_ONE.dup
    assert_equal(nil, MindFreak.check_program(program))
    # Default size tape
    assert_equal(
      "#include <stdio.h>\nint main(){\n  unsigned int tape[#{MindFreak::TAPE_DEFAULT_SIZE}] = {0};\n  unsigned int *pointer = tape;\n  *(pointer) = 1;\n  return 0;\n}",
      MindFreak.to_c(program, [])
    )
    # User size tape
    tape = [0,0]
    assert_equal(
      "#include <stdio.h>\nint main(){\n  unsigned int tape[#{tape.size}] = {0};\n  unsigned int *pointer = tape;\n  *(pointer) = 1;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  def test_to_c_sum
    program = SUM.dup
    assert_equal(nil, MindFreak.check_program(program))
    # Default size tape
    assert_equal(
      "#include <stdio.h>\nint main(){\n  unsigned int tape[#{MindFreak::TAPE_DEFAULT_SIZE}] = {0};\n  unsigned int *pointer = tape;\n  *(pointer+1) += *(pointer);\n  *(pointer) = 0;\n  return 0;\n}",
      MindFreak.to_c(program, [])
    )
    # User size tape
    tape = [0,0]
    assert_equal(
      "#include <stdio.h>\nint main(){\n  unsigned int tape[#{tape.size}] = {0};\n  unsigned int *pointer = tape;\n  *(pointer+1) += *(pointer);\n  *(pointer) = 0;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  #-----------------------------------------------
  # Bytecode
  #-----------------------------------------------

  def test_bytecode_set_one
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
    # Optimized bytecode uses [instruction, argument, offset, set or multiplier]
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
    # Optimized bytecode uses [instruction, argument, offset, set or multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  1, nil, 1],
        [MindFreak::INCREMENT, 0, nil, true]
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
    # Optimized bytecode uses [instruction, argument, offset, set or multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 1,  1, nil],
        [MindFreak::WRITE,     1, -1, nil],
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end

  def test_bytecode_copy
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.make_bytecode('[->>+>+<<<]')
    assert_equal(
      [
        [MindFreak::JUMP,       7],
        [MindFreak::INCREMENT, -1],
        [MindFreak::FORWARD,    2],
        [MindFreak::INCREMENT,  1],
        [MindFreak::FORWARD,    1],
        [MindFreak::INCREMENT,  1],
        [MindFreak::FORWARD,   -3],
        [MindFreak::JUMPBACK,   0]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, set or multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, nil, 1],
        [MindFreak::MULTIPLY,  3, nil, 1],
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end

  def test_bytecode_multiply
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.make_bytecode('[->>+++++>++<<<]')
    assert_equal(
      [
        [MindFreak::JUMP,       7],
        [MindFreak::INCREMENT, -1],
        [MindFreak::FORWARD,    2],
        [MindFreak::INCREMENT,  5],
        [MindFreak::FORWARD,    1],
        [MindFreak::INCREMENT,  2],
        [MindFreak::FORWARD,   -3],
        [MindFreak::JUMPBACK,   0]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, set or multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, nil, 5],
        [MindFreak::MULTIPLY,  3, nil, 2],
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end

  def test_bytecode_multiply_with_offset
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.make_bytecode('>>[->>+++++>++<<<]')
    assert_equal(
      [
        [MindFreak::FORWARD,    2],
        [MindFreak::JUMP,       8],
        [MindFreak::INCREMENT, -1],
        [MindFreak::FORWARD,    2],
        [MindFreak::INCREMENT,  5],
        [MindFreak::FORWARD,    1],
        [MindFreak::INCREMENT,  2],
        [MindFreak::FORWARD,   -3],
        [MindFreak::JUMPBACK,   1]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, set or multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, 2, 5],
        [MindFreak::MULTIPLY,  3, 2, 2],
        [MindFreak::INCREMENT, 0, 2, true]
      ],
      MindFreak.optimize_bytecode(bytecode)
    )
  end

  def test_bytecode_mandelbrot
    # Check bytecode size
    program = IO.read('mandelbrot.bf')
    assert_equal(nil, MindFreak.check_program(program))
    bytecode = MindFreak.make_bytecode(program)
    assert_equal(4115, bytecode.size)
    assert_equal(2248, MindFreak.optimize_bytecode(bytecode).size)
  end
end