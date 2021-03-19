require 'test/unit'
require 'stringio'
require './MindFreak'

class Rorschach < Test::Unit::TestCase

  ASSIGN = '[-]+'
  SUM = '[->+<] Subtract one from first cell; add to the second; repeat until first cell is zero'
  HELLO = ',,,.,.,..,.>.'

  def test_attributes
    [:pointer, :input, :input=, :output, :output=, :debug, :debug=].each {|att| assert_respond_to(MindFreak, att)}
  end

  #-----------------------------------------------
  # Check
  #-----------------------------------------------

  def test_check_empty
    # Return same string
    program = ''
    assert_nil(MindFreak.check(program))
    assert_equal('', program)
  end

  def test_check_comment_removal
    # Remove unknown characters
    program = "abc<>[]--++#,.()123_-=;\n"
    assert_nil(MindFreak.check(program))
    assert_equal('<>[]--++,.-', program)
  end

  def test_check_open_bracket_exception
    # Expected to raise an exception
    e = assert_raises(RuntimeError) {MindFreak.check('[-[')}
    assert_equal('Expected ]', e.message)
  end

  def test_check_close_bracket_exception
    # Expected to raise an exception
    e = assert_raises(RuntimeError) {MindFreak.check('[-]]')}
    assert_equal('Unexpected ] found', e.message)
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def test_run_interpreter_assign
    # Clear first cell and add one
    program = ASSIGN.dup
    tape = [10]
    assert_nil(MindFreak.check(program))
    assert_equal(ASSIGN, program)
    MindFreak.run_interpreter(program, tape)
    assert_equal([1], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_interpreter_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_nil(MindFreak.check(program))
    assert_equal('[->+<]', program)
    MindFreak.run_interpreter(program, tape)
    assert_equal([0, 15], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_interpreter_io
    # Using StringIO to simulate input/output
    program = HELLO.dup
    tape = [0, 33]
    MindFreak.input = StringIO.new('  Helo')
    MindFreak.output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_interpreter(program, tape)
    assert_equal([111, 33], tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('  Helo', MindFreak.input.string)
    assert_equal('Hello!', MindFreak.output.string)
  end

  def test_run_interpreter_io_read_eof
    program = ','
    tape = [0]
    MindFreak.input = StringIO.new
    assert_nil(MindFreak.check(program))
    # Expected to raise an exception
    MindFreak.run_interpreter(program, tape)
    assert_equal([0], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', MindFreak.input.string)
  end

  #-----------------------------------------------
  # Run bytecode
  #-----------------------------------------------

  def test_run_bytecode_assign
    # Clear first cell and add one
    program = ASSIGN.dup
    tape = [10]
    assert_nil(MindFreak.check(program))
    assert_equal(ASSIGN, program)
    MindFreak.run_bytecode(program, tape)
    assert_equal([1], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_nil(MindFreak.check(program))
    assert_equal('[->+<]', program)
    MindFreak.run_bytecode(program, tape)
    assert_equal([0, 15], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode_io
    # Using StringIO to simulate input/output
    program = HELLO.dup
    tape = [0, 33]
    MindFreak.input = StringIO.new('  Helo')
    MindFreak.output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode(program, tape)
    assert_equal([111, 33], tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('  Helo', MindFreak.input.string)
    assert_equal('Hello!', MindFreak.output.string)
  end

  def test_run_bytecode_io_read_eof
    program = ','
    tape = [0]
    MindFreak.input = StringIO.new
    assert_nil(MindFreak.check(program))
    # Expected to raise an exception
    MindFreak.run_bytecode(program, tape)
    assert_equal([0], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', MindFreak.input.string)
  end

  #-----------------------------------------------
  # Run bytecode2
  #-----------------------------------------------

  def test_run_bytecode2_assign
    # Clear first cell and add one
    program = ASSIGN.dup
    tape = [10]
    assert_nil(MindFreak.check(program))
    assert_equal(ASSIGN, program)
    MindFreak.run_bytecode2(program, tape)
    assert_equal([1], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode2_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    assert_nil(MindFreak.check(program))
    assert_equal('[->+<]', program)
    MindFreak.run_bytecode2(program, tape)
    assert_equal([0, 15], tape)
    assert_equal(0, MindFreak.pointer)
  end

  def test_run_bytecode2_io
    # Using StringIO to simulate input/output
    program = HELLO.dup
    tape = [0, 33]
    MindFreak.input = StringIO.new('  Helo')
    MindFreak.output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode2(program, tape)
    assert_equal([111, 33], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('  Helo', MindFreak.input.string)
    assert_equal('Hello!', MindFreak.output.string)
  end

  def test_run_bytecode2_io_read_eof
    program = ','
    tape = [0]
    MindFreak.input = StringIO.new
    assert_nil(MindFreak.check(program))
    # Expected to raise an exception
    MindFreak.run_bytecode2(program, tape)
    assert_equal([0], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', MindFreak.input.string)
  end

  #-----------------------------------------------
  # Eval Ruby
  #-----------------------------------------------

  def test_eval_ruby_assign
    # Clear first cell and add one
    program = ASSIGN.dup
    tape = [10]
    # Ruby evaluation mode requires local pointer
    pointer = 0
    assert_nil(MindFreak.check(program))
    assert_equal(ASSIGN, program)
    eval(MindFreak.to_ruby(program))
    assert_equal([1], tape)
    assert_equal(0, pointer)
  end

  def test_eval_ruby_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    # Ruby evaluation mode requires local pointer
    pointer = 0
    assert_nil(MindFreak.check(program))
    assert_equal('[->+<]', program)
    eval(MindFreak.to_ruby(program))
    assert_equal([0, 15], tape)
    assert_equal(0, pointer)
  end

  def test_eval_ruby_io
    # Using StringIO to simulate input/output
    input = StringIO.new('  Helo')
    output = StringIO.new
    program = HELLO.dup
    tape = [0, 33]
    # Ruby evaluation mode requires local pointer
    pointer = 0
    assert_nil(MindFreak.check(program))
    # Connect input and output local variables
    eval(MindFreak.to_ruby(program, nil, 'input', 'output'))
    assert_equal([111, 33], tape)
    assert_equal(0, pointer)
    assert_equal('  Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  #-----------------------------------------------
  # to Ruby
  #-----------------------------------------------

  def test_to_ruby_assign
    program = ASSIGN.dup
    assert_nil(MindFreak.check(program))
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
    assert_nil(MindFreak.check(program))
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0\ntape[pointer+1] += tape[pointer]\ntape[pointer] = 0",
      MindFreak.to_ruby(program, [])
    )
    # Array tape
    assert_equal(
      "tape = Array.new(2,0)\npointer = 0\ntape[pointer+1] += tape[pointer]\ntape[pointer] = 0",
      MindFreak.to_ruby(program, [5,10])
    )
    assert_equal(
      "tape = Array.new(2,0)\npointer = 0",
      MindFreak.to_ruby(program, [0,10])
    )
  end

  def test_to_ruby_read_consecutive
    program = ',,,,,'
    assert_nil(MindFreak.check(program))
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0\nSTDIN.read(4)\ntape[pointer] = STDIN.getbyte.to_i",
      MindFreak.to_ruby(program, [])
    )
    # Array tape
    assert_equal(
      "tape = Array.new(1,0)\npointer = 0\nSTDIN.read(4)\ntape[pointer] = STDIN.getbyte.to_i",
      MindFreak.to_ruby(program, [0])
    )
  end

  def test_to_ruby_infinite_loop
    program = '[]'
    assert_nil(MindFreak.check(program))
    # Default tape size
    assert_equal(
      "tape = Hash.new(0)\npointer = 0\nuntil tape[pointer].zero?\nend",
      MindFreak.to_ruby(program, [])
    )
  end

  #-----------------------------------------------
  # to C
  #-----------------------------------------------

  def c_header(tape_size)
    "#include <stdio.h>\nint main(){\n  unsigned int tape[#{tape_size}] = {0}, *pointer = tape;\n  "
  end

  def test_to_c_assign
    program = ASSIGN.dup
    assert_nil(MindFreak.check(program))
    # Default tape size
    assert_equal(
      "#{c_header(MindFreak::TAPE_DEFAULT_SIZE)}*(pointer) = 1;\n  return 0;\n}",
      MindFreak.to_c(program, [])
    )
    # User tape size
    tape = [0,0]
    assert_equal(
      "#{c_header(2)}*(pointer) = 1;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  def test_to_c_sum
    program = SUM.dup
    assert_nil(MindFreak.check(program))
    # Default tape size
    assert_equal(
      "#{c_header(MindFreak::TAPE_DEFAULT_SIZE)}*(pointer+1) += *(pointer);\n  *(pointer) = 0;\n  return 0;\n}",
      MindFreak.to_c(program, [])
    )
    # User tape size
    tape = [5,10]
    assert_equal(
      "#{c_header(2)}*(pointer+1) += *(pointer);\n  *(pointer) = 0;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  def test_to_c_read_consecutive
    program = ',,,,,'
    assert_nil(MindFreak.check(program))
    # Default tape size
    assert_equal(
      "#{c_header(MindFreak::TAPE_DEFAULT_SIZE)}for(unsigned int i = 4; i; --i) getchar();\n  (*(pointer)) = getchar();\n  return 0;\n}",
      MindFreak.to_c(program, [], -1)
    )
    assert_equal(
      "#{c_header(MindFreak::TAPE_DEFAULT_SIZE)}int c;\n  for(unsigned int i = 4; i; --i) getchar();\n  c = getchar();\n  (*(pointer)) = c == EOF ? 0 : c;\n  return 0;\n}",
      MindFreak.to_c(program, [])
    )
    # User tape size
    tape = [0,0]
    assert_equal(
      "#{c_header(2)}for(unsigned int i = 4; i; --i) getchar();\n  (*(pointer)) = getchar();\n  return 0;\n}",
      MindFreak.to_c(program, tape, -1)
    )
    assert_equal(
      "#{c_header(2)}int c;\n  for(unsigned int i = 4; i; --i) getchar();\n  c = getchar();\n  (*(pointer)) = c == EOF ? 0 : c;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  def test_to_c_infinite_loop
    program = '[]'
    assert_nil(MindFreak.check(program))
    # Default tape size
    assert_equal(
      "#{c_header(MindFreak::TAPE_DEFAULT_SIZE)}while(*pointer){\n  }\n  return 0;\n}",
      MindFreak.to_c(program, [], -1)
    )
  end

  #-----------------------------------------------
  # Bytecode
  #-----------------------------------------------

  def test_bytecode_assign
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode(ASSIGN)
    assert_equal(
      [
        [MindFreak::JUMP,       2],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   0],
        [MindFreak::INCREMENT,  1]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 1, nil, true]
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_sum
    # Bytecode uses [instruction, argument]
    program = SUM.dup
    MindFreak.check(program)
    bytecode = MindFreak.bytecode(program)
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
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  1, nil, nil, 1],
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize(bytecode.dup)
    )
    assert_equal([], MindFreak.optimize(bytecode, true))
  end

  def test_bytecode_nullification
    # Empty
    assert_equal([], MindFreak.bytecode(''))
    # Add and subtract
    assert_equal([], MindFreak.bytecode('+++---'))
    # Subtract and add
    assert_equal([], MindFreak.bytecode('---+++'))
    # Add one
    assert_equal([[MindFreak::INCREMENT, 1]], MindFreak.bytecode('---++++'))
    # Check if pairs match
    assert_equal([], MindFreak.bytecode('+>>-<>+<<-'))
    # Forward and backward
    assert_equal([], MindFreak.bytecode('>><<'))
    # Backward and forward
    assert_equal([], MindFreak.bytecode('<<>>'))
    # Empty bytecode is optimal
    assert_equal([], MindFreak.optimize([]))
    # Clear
    assert_equal([[MindFreak::INCREMENT, 0, nil, true]], MindFreak.optimize(MindFreak.bytecode('+[-]')))
    # Mix increments and movements
    assert_equal([[MindFreak::INCREMENT, 1]], MindFreak.bytecode('-+>+-<+'))
    # Mix with loops
    assert_equal(
      [
        [MindFreak::JUMP, 3],
        [MindFreak::JUMP, 2],
        [MindFreak::JUMPBACK, 1],
        [MindFreak::JUMPBACK, 0],
        [MindFreak::JUMP, 5],
        [MindFreak::JUMPBACK, 4]
      ],
      MindFreak.bytecode('[<>[]+-][]')
    )
  end

  def test_bytecode_offset
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('>+<<.>')
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
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 1,  1],
        [MindFreak::WRITE,     1, -1]
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_offset_with_jump
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('[>+<<.>[.]]')
    assert_equal(
      [
        [MindFreak::JUMP,      9],
        [MindFreak::FORWARD,   1],
        [MindFreak::INCREMENT, 1],
        [MindFreak::FORWARD,  -2],
        [MindFreak::WRITE,     1],
        [MindFreak::FORWARD,   1],
        [MindFreak::JUMP,      8],
        [MindFreak::WRITE,     1],
        [MindFreak::JUMPBACK,  6],
        [MindFreak::JUMPBACK,  0]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::JUMP,      6],
        [MindFreak::INCREMENT, 1,  1],
        [MindFreak::WRITE,     1, -1],
        [MindFreak::JUMP,      5],
        [MindFreak::WRITE,     1],
        [MindFreak::JUMPBACK,  3],
        [MindFreak::JUMPBACK,  0]
      ],
      MindFreak.optimize(bytecode)
    )
    assert_equal([], MindFreak.optimize(bytecode, true))
  end

  def test_bytecode_copy
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('[->>+>+<<<]')
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
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, nil, nil, 1],
        [MindFreak::MULTIPLY,  3, nil, nil, 1],
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize(bytecode.dup)
    )
    assert_equal([], MindFreak.optimize(bytecode, true))
  end

  def test_bytecode_multiply
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('[->>+++++>++<<<]')
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
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, nil, nil, 5],
        [MindFreak::MULTIPLY,  3, nil, nil, 2],
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize(bytecode.dup)
    )
    assert_equal([], MindFreak.optimize(bytecode, true))
  end

  def test_bytecode_multiply_with_offset
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('>>[->>+++++>++<<<]')
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
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, 2, nil, 5],
        [MindFreak::MULTIPLY,  3, 2, nil, 2],
        [MindFreak::INCREMENT, 0, 2, true]
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_multiply_assign
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('>>[-]<<[->>+<<]')
    assert_equal(
      [
        [MindFreak::FORWARD,    2],
        [MindFreak::JUMP,       3],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   1],
        [MindFreak::FORWARD,   -2],
        [MindFreak::JUMP,      10],
        [MindFreak::INCREMENT, -1],
        [MindFreak::FORWARD,    2],
        [MindFreak::INCREMENT,  1],
        [MindFreak::FORWARD,   -2],
        [MindFreak::JUMPBACK,   5]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::MULTIPLY,  2, nil, true, 1],
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_multiply_with_clear
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('[-][->+<][-]')
    assert_equal(
      [
        [MindFreak::JUMP,       2],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   0],
        [MindFreak::JUMP,       8],
        [MindFreak::INCREMENT, -1],
        [MindFreak::FORWARD,    1],
        [MindFreak::INCREMENT,  1],
        [MindFreak::FORWARD,   -1],
        [MindFreak::JUMPBACK,   3],
        [MindFreak::JUMP,      11],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   9]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 0, nil, true],
        [MindFreak::MULTIPLY,  1, nil, nil, 1],
        [MindFreak::INCREMENT, 0, nil, true],
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_redundant_set_value
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('++[-]+++[-]++[-]+')
    assert_equal(
      [
        [MindFreak::INCREMENT,  2],
        [MindFreak::JUMP,       3],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   1],
        [MindFreak::INCREMENT,  3],
        [MindFreak::JUMP,       7],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   5],
        [MindFreak::INCREMENT,  2],
        [MindFreak::JUMP,      11],
        [MindFreak::INCREMENT, -1],
        [MindFreak::JUMPBACK,   9],
        [MindFreak::INCREMENT,  1]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 1, nil, true]
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_hello_world
    program = '>+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.>>>
    ++++++++[<++++>-]<.>>>++++++++++[<+++++++++>-]<---.<<<<.+++
    .------.--------.>>+.'
    # Remove spaces and newlines
    assert_nil(MindFreak.check(program))
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 9, 1],
        [MindFreak::MULTIPLY, -1, 1, nil, 8],
        [MindFreak::INCREMENT, 0, 1, true],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, 7, 1],
        [MindFreak::MULTIPLY, -1, 1, nil, 4],
        [MindFreak::INCREMENT, 0, 1, true],
        [MindFreak::INCREMENT, 1],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, 7],
        [MindFreak::WRITE, 2],
        [MindFreak::INCREMENT, 3],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, 8, 3],
        [MindFreak::MULTIPLY, -1, 3, nil, 4],
        [MindFreak::INCREMENT, 0, 3, true],
        [MindFreak::WRITE, 1, 2],
        [MindFreak::INCREMENT, 10, 5],
        [MindFreak::MULTIPLY, -1, 5, nil, 9],
        [MindFreak::INCREMENT, 0, 5, true],
        [MindFreak::INCREMENT, -3, 4],
        [MindFreak::WRITE, 1, 4],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, 3],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, -6],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, -8],
        [MindFreak::WRITE, 1],
        [MindFreak::INCREMENT, 1, 2],
        [MindFreak::WRITE, 1, 2]
      ],
      MindFreak.optimize(MindFreak.bytecode(program))
    )
    # Using StringIO to simulate output
    MindFreak.output = StringIO.new
    MindFreak.run_interpreter(program, Array.new(10, 0))
    assert_equal('Hello World!', MindFreak.output.string)
  end

  def test_bytecode_mandelbrot
    filename = 'mandelbrot.bf'
    file_c = "#{filename}.c"
    file_exe = "#{filename}.exe"
    # Check bytecode size
    program = IO.read(filename)
    assert_nil(MindFreak.check(program))
    bytecode = MindFreak.bytecode(program)
    assert_equal(4115, bytecode.size)
    assert_equal(2177, MindFreak.optimize(bytecode).size)
    # Compare output
    File.delete(file_c) if File.exist?(file_c)
    File.delete(file_exe) if File.exist?(file_exe)
    IO.write(file_c, MindFreak.to_c(program, nil, -1))
    system("gcc #{file_c} -o #{file_exe} -O2 -s")
    assert_equal(
'AAAAAAAAAAAAAAAABBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDEGFFEEEEDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
AAAAAAAAAAAAAAABBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDEEEFGIIGFFEEEDDDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBB
AAAAAAAAAAAAABBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDEEEEFFFI KHGGGHGEDDDDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBB
AAAAAAAAAAAABBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDEEEEEFFGHIMTKLZOGFEEDDDDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBB
AAAAAAAAAAABBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDEEEEEEFGGHHIKPPKIHGFFEEEDDDDDDDDDCCCCCCCCCCBBBBBBBBBBBBBBBBBB
AAAAAAAAAABBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDEEEEEEFFGHIJKS  X KHHGFEEEEEDDDDDDDDDCCCCCCCCCCBBBBBBBBBBBBBBBB
AAAAAAAAABBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDEEEEEEFFGQPUVOTY   ZQL[MHFEEEEEEEDDDDDDDCCCCCCCCCCCBBBBBBBBBBBBBB
AAAAAAAABBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDEEEEEFFFFFGGHJLZ         UKHGFFEEEEEEEEDDDDDCCCCCCCCCCCCBBBBBBBBBBBB
AAAAAAABBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDEEEEFFFFFFGGGGHIKP           KHHGGFFFFEEEEEEDDDDDCCCCCCCCCCCBBBBBBBBBBB
AAAAAAABBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDEEEEEFGGHIIHHHHHIIIJKMR        VMKJIHHHGFFFFFFGSGEDDDDCCCCCCCCCCCCBBBBBBBBB
AAAAAABBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDEEEEEEFFGHK   MKJIJO  N R  X      YUSR PLV LHHHGGHIOJGFEDDDCCCCCCCCCCCCBBBBBBBB
AAAAABBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDEEEEEEEEEFFFFGH O    TN S                       NKJKR LLQMNHEEDDDCCCCCCCCCCCCBBBBBBB
AAAAABBCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDEEEEEEEEEEEEFFFFFGHHIN                                 Q     UMWGEEEDDDCCCCCCCCCCCCBBBBBB
AAAABBCCCCCCCCCCCCCCCCCCCCCCCCCDDDDEEEEEEEEEEEEEEEFFFFFFGHIJKLOT                                     [JGFFEEEDDCCCCCCCCCCCCCBBBBB
AAAABCCCCCCCCCCCCCCCCCCCCCCDDDDEEEEEEEEEEEEEEEEFFFFFFGGHYV RQU                                     QMJHGGFEEEDDDCCCCCCCCCCCCCBBBB
AAABCCCCCCCCCCCCCCCCCDDDDDDDEEFJIHFFFFFFFFFFFFFFGGGGGGHIJN                                            JHHGFEEDDDDCCCCCCCCCCCCCBBB
AAABCCCCCCCCCCCDDDDDDDDDDEEEEFFHLKHHGGGGHHMJHGGGGGGHHHIKRR                                           UQ L HFEDDDDCCCCCCCCCCCCCCBB
AABCCCCCCCCDDDDDDDDDDDEEEEEEFFFHKQMRKNJIJLVS JJKIIIIIIJLR                                               YNHFEDDDDDCCCCCCCCCCCCCBB
AABCCCCCDDDDDDDDDDDDEEEEEEEFFGGHIJKOU  O O   PR LLJJJKL                                                OIHFFEDDDDDCCCCCCCCCCCCCCB
AACCCDDDDDDDDDDDDDEEEEEEEEEFGGGHIJMR              RMLMN                                                 NTFEEDDDDDDCCCCCCCCCCCCCB
AACCDDDDDDDDDDDDEEEEEEEEEFGGGHHKONSZ                QPR                                                NJGFEEDDDDDDCCCCCCCCCCCCCC
ABCDDDDDDDDDDDEEEEEFFFFFGIPJIIJKMQ                   VX                                                 HFFEEDDDDDDCCCCCCCCCCCCCC
ACDDDDDDDDDDEFFFFFFFGGGGHIKZOOPPS                                                                      HGFEEEDDDDDDCCCCCCCCCCCCCC
ADEEEEFFFGHIGGGGGGHHHHIJJLNY                                                                        TJHGFFEEEDDDDDDDCCCCCCCCCCCCC
A                                                                                                 PLJHGGFFEEEDDDDDDDCCCCCCCCCCCCC
ADEEEEFFFGHIGGGGGGHHHHIJJLNY                                                                        TJHGFFEEEDDDDDDDCCCCCCCCCCCCC
ACDDDDDDDDDDEFFFFFFFGGGGHIKZOOPPS                                                                      HGFEEEDDDDDDCCCCCCCCCCCCCC
ABCDDDDDDDDDDDEEEEEFFFFFGIPJIIJKMQ                   VX                                                 HFFEEDDDDDDCCCCCCCCCCCCCC
AACCDDDDDDDDDDDDEEEEEEEEEFGGGHHKONSZ                QPR                                                NJGFEEDDDDDDCCCCCCCCCCCCCC
AACCCDDDDDDDDDDDDDEEEEEEEEEFGGGHIJMR              RMLMN                                                 NTFEEDDDDDDCCCCCCCCCCCCCB
AABCCCCCDDDDDDDDDDDDEEEEEEEFFGGHIJKOU  O O   PR LLJJJKL                                                OIHFFEDDDDDCCCCCCCCCCCCCCB
AABCCCCCCCCDDDDDDDDDDDEEEEEEFFFHKQMRKNJIJLVS JJKIIIIIIJLR                                               YNHFEDDDDDCCCCCCCCCCCCCBB
AAABCCCCCCCCCCCDDDDDDDDDDEEEEFFHLKHHGGGGHHMJHGGGGGGHHHIKRR                                           UQ L HFEDDDDCCCCCCCCCCCCCCBB
AAABCCCCCCCCCCCCCCCCCDDDDDDDEEFJIHFFFFFFFFFFFFFFGGGGGGHIJN                                            JHHGFEEDDDDCCCCCCCCCCCCCBBB
AAAABCCCCCCCCCCCCCCCCCCCCCCDDDDEEEEEEEEEEEEEEEEFFFFFFGGHYV RQU                                     QMJHGGFEEEDDDCCCCCCCCCCCCCBBBB
AAAABBCCCCCCCCCCCCCCCCCCCCCCCCCDDDDEEEEEEEEEEEEEEEFFFFFFGHIJKLOT                                     [JGFFEEEDDCCCCCCCCCCCCCBBBBB
AAAAABBCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDEEEEEEEEEEEEFFFFFGHHIN                                 Q     UMWGEEEDDDCCCCCCCCCCCCBBBBBB
AAAAABBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDEEEEEEEEEFFFFGH O    TN S                       NKJKR LLQMNHEEDDDCCCCCCCCCCCCBBBBBBB
AAAAAABBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDEEEEEEFFGHK   MKJIJO  N R  X      YUSR PLV LHHHGGHIOJGFEDDDCCCCCCCCCCCCBBBBBBBB
AAAAAAABBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDEEEEEFGGHIIHHHHHIIIJKMR        VMKJIHHHGFFFFFFGSGEDDDDCCCCCCCCCCCCBBBBBBBBB
AAAAAAABBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDEEEEFFFFFFGGGGHIKP           KHHGGFFFFEEEEEEDDDDDCCCCCCCCCCCBBBBBBBBBBB
AAAAAAAABBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDEEEEEFFFFFGGHJLZ         UKHGFFEEEEEEEEDDDDDCCCCCCCCCCCCBBBBBBBBBBBB
AAAAAAAAABBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDEEEEEEFFGQPUVOTY   ZQL[MHFEEEEEEEDDDDDDDCCCCCCCCCCCBBBBBBBBBBBBBB
AAAAAAAAAABBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDDEEEEEEFFGHIJKS  X KHHGFEEEEEDDDDDDDDDCCCCCCCCCCBBBBBBBBBBBBBBBB
AAAAAAAAAAABBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDEEEEEEFGGHHIKPPKIHGFFEEEDDDDDDDDDCCCCCCCCCCBBBBBBBBBBBBBBBBBB
AAAAAAAAAAAABBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDDDEEEEEFFGHIMTKLZOGFEEDDDDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBB
AAAAAAAAAAAAABBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDDDEEEEFFFI KHGGGHGEDDDDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBB
AAAAAAAAAAAAAAABBBBBBBBBBBBBCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCDDDDDDDDDDEEEFGIIGFFEEEDDDDDDDDCCCCCCCCCBBBBBBBBBBBBBBBBBBBBBBBBBB
', `./#{file_exe}`)
  ensure
    File.delete(file_c) if File.exist?(file_c)
    File.delete(file_exe) if File.exist?(file_exe)
  end
end