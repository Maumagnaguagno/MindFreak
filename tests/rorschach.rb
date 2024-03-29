require 'test/unit'
require 'stringio'
require './MindFreak'

class Rorschach < Test::Unit::TestCase

  ASSIGN = '[-]+'
  SUM = '[->+<] Subtract one from first cell; add to the second; repeat until first cell is zero'
  HELLO = ',,,.,.,..,.>.'
  HELLO_WORLD = '>+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.>>>
               ++++++++[<++++>-]<.>>>++++++++++[<+++++++++>-]<---.<<<<.+++
               .------.--------.>>+.'

  def test_attributes
    [:pointer, :debug=].each {|att| assert_respond_to(MindFreak, att)}
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
    input = StringIO.new('  Helo')
    output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_interpreter(program, tape, 0, input, output)
    assert_equal([111, 33], tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('  Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  def test_run_interpreter_io_read_eof
    # Consider any integer as EOF
    program = ','
    tape = [0]
    input = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_interpreter(program, tape, 0, input)
    assert_equal([0], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
    MindFreak.run_interpreter(program, tape, 255, input)
    assert_equal([255], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
    MindFreak.run_interpreter(program, tape = [], nil, input)
    assert_equal([], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
  end

  def test_run_interpreter_hello_world
    # Using StringIO to simulate output
    program = HELLO_WORLD.dup
    output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_interpreter(program, Array.new(10, 0), 0, nil, output)
    assert_equal('Hello World!', output.string)
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
    input = StringIO.new('  Helo')
    output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode(program, tape, 0, input, output)
    assert_equal([111, 33], tape)
    assert_equal(1, MindFreak.pointer)
    assert_equal('  Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  def test_run_bytecode_io_read_eof
    # Consider any integer as EOF
    program = ','
    tape = [0]
    input = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode(program, tape, 0, input)
    assert_equal([0], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
    MindFreak.run_bytecode(program, tape, 255, input)
    assert_equal([255], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
    MindFreak.run_bytecode(program, tape = [], nil, input)
    assert_equal([], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
  end

  def test_run_bytecode_hello_world
    # Using StringIO to simulate output
    program = HELLO_WORLD.dup
    output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode(program, Array.new(10, 0), 0, nil, output)
    assert_equal('Hello World!', output.string)
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
    input = StringIO.new('  Helo')
    output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode2(program, tape, 0, input, output)
    assert_equal([111, 33], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('  Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  def test_run_bytecode2_io_read_eof
    # Consider any integer as EOF
    program = ','
    tape = [0]
    input = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode2(program, tape, 0, input)
    assert_equal([0], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
    MindFreak.run_bytecode2(program, tape, 255, input)
    assert_equal([255], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
    MindFreak.run_bytecode2(program, tape = [], nil, input)
    assert_equal([], tape)
    assert_equal(0, MindFreak.pointer)
    assert_equal('', input.string)
  end

  def test_run_bytecode2_hello_world
    # Using StringIO to simulate output
    program = HELLO_WORLD.dup
    output = StringIO.new
    assert_nil(MindFreak.check(program))
    MindFreak.run_bytecode2(program, Array.new(10, 0), 0, nil, output)
    assert_equal('Hello World!', output.string)
  end

  #-----------------------------------------------
  # Eval Ruby
  #-----------------------------------------------

  def test_eval_ruby_assign
    # Clear first cell and add one
    program = ASSIGN.dup
    tape = [10]
    pointer = 0
    assert_nil(MindFreak.check(program))
    assert_equal(ASSIGN, program)
    eval(MindFreak.to_ruby(program, tape))
    assert_equal([1], tape)
    assert_equal(0, pointer)
  end

  def test_eval_ruby_sum
    # Sum elements of tape
    program = SUM.dup
    tape = [5, 10]
    pointer = 0
    assert_nil(MindFreak.check(program))
    assert_equal('[->+<]', program)
    eval(MindFreak.to_ruby(program, tape))
    assert_equal([0, 15], tape)
    assert_equal(0, pointer)
  end

  def test_eval_ruby_io
    # Using StringIO to simulate input/output
    input = StringIO.new('  Helo')
    output = StringIO.new
    program = HELLO.dup
    tape = [0, 33]
    pointer = 0
    assert_nil(MindFreak.check(program))
    # Connect input and output local variables
    eval(MindFreak.to_ruby(program, tape, 0, 'input', 'output'))
    assert_equal([111, 33], tape)
    assert_equal(0, pointer)
    assert_equal('  Helo', input.string)
    assert_equal('Hello!', output.string)
  end

  def test_eval_ruby_io_read_eof
    # Consider any integer as EOF
    input = StringIO.new
    program = ','
    tape = [0]
    pointer = 0
    assert_nil(MindFreak.check(program))
    eval(MindFreak.to_ruby(program, tape, 0, 'input'))
    assert_equal([0], tape)
    assert_equal(0, pointer)
    assert_equal('', input.string)
    eval(MindFreak.to_ruby(program, tape, 255, 'input'))
    assert_equal([255], tape)
    assert_equal(0, pointer)
    assert_equal('', input.string)
    eval(MindFreak.to_ruby(program, tape, nil, 'input'))
    assert_equal([255], tape)
    assert_equal(0, pointer)
    assert_equal('', input.string)
  end

  def test_eval_ruby_hello_world
    # Using StringIO to simulate output
    output = StringIO.new
    program = HELLO_WORLD.dup
    tape = Array.new(10, 0)
    assert_nil(MindFreak.check(program))
    eval(MindFreak.to_ruby(program, tape, 0, nil, 'output'))
    assert_equal('Hello World!', output.string)
  end

  #-----------------------------------------------
  # to Ruby
  #-----------------------------------------------

  def test_to_ruby_assign
    program = ASSIGN.dup
    assert_nil(MindFreak.check(program))
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0\ntape[0] = 1",
      MindFreak.to_ruby(program, 0)
    )
    # Array tape
    assert_equal(
      "tape = Array.new(1,0)\npointer = 0\ntape[0] = 1",
      MindFreak.to_ruby(program, 1)
    )
  end

  def test_to_ruby_sum
    program = SUM.dup
    assert_nil(MindFreak.check(program))
    # Hash tape
    assert_equal(
      "\ntape[1] += tape[0]\ntape[0] = 0",
      MindFreak.to_ruby(program, {})
    )
    assert_equal(
      "tape = Hash.new(0)\npointer = 0",
      MindFreak.to_ruby(program, 0)
    )
    # Array tape
    assert_equal(
      "\ntape[1] += tape[0]\ntape[0] = 0",
      MindFreak.to_ruby(program, [5,10])
    )
    assert_equal('', MindFreak.to_ruby(program, [0,10]))
    assert_equal(
      "tape = Array.new(20,0)\npointer = 0",
      MindFreak.to_ruby(program, 20)
    )
    assert_equal(
      "tape = Array.new(#{MindFreak::TAPE_DEFAULT_SIZE},0)\npointer = 0",
      MindFreak.to_ruby(program)
    )
  end

  def test_to_ruby_read_consecutive
    program = ',,,,,'
    assert_nil(MindFreak.check(program))
    eof_zero = "\nSTDIN.read(4)\ntape[0] = STDIN.getbyte || 0"
    eof_minus_one = "\nSTDIN.read(4)\ntape[0] = STDIN.getbyte || -1"
    eof_unchanged = "\nSTDIN.read(4)\nc = STDIN.getbyte and tape[0] = c"
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0" << eof_zero,
      MindFreak.to_ruby(program, 0)
    )
    assert_equal(
      "tape = Hash.new(0)\npointer = 0" << eof_minus_one,
      MindFreak.to_ruby(program, 0, -1)
    )
    assert_equal(
      "tape = Hash.new(0)\npointer = 0" << eof_unchanged,
      MindFreak.to_ruby(program, 0, nil)
    )
    # Array tape
    assert_equal(
      eof_zero,
      MindFreak.to_ruby(program, [0])
    )
    assert_equal(
      eof_minus_one,
      MindFreak.to_ruby(program, [0], -1)
    )
    assert_equal(
      eof_unchanged,
      MindFreak.to_ruby(program, [0], nil)
    )
  end

  def test_to_ruby_infinite_loop
    program = '[]'
    assert_nil(MindFreak.check(program))
    # Hash tape
    assert_equal(
      "tape = Hash.new(0)\npointer = 0",
      MindFreak.to_ruby(program, 0)
    )
    assert_equal(
      "\nwhile tape[pointer] != 0\nend",
      MindFreak.to_ruby(program, {})
    )
    # Array tape
    assert_equal(
      "tape = Array.new(5,0)\npointer = 0",
      MindFreak.to_ruby(program, 5)
    )
    assert_equal('', MindFreak.to_ruby(program, [0]))
    assert_equal(
      "\nwhile tape[pointer] != 0\nend",
      MindFreak.to_ruby(program, [])
    )
  end

  #-----------------------------------------------
  # to C
  #-----------------------------------------------

  def c_header(tape_size = MindFreak::TAPE_DEFAULT_SIZE, tape_str = '0')
    "#include <stdio.h>\nint main(){\n  unsigned int tape[#{tape_size}] = {#{tape_str}}, *pointer = tape;\n  "
  end

  def test_to_c_assign
    program = ASSIGN.dup
    assert_nil(MindFreak.check(program))
    # Default tape
    assert_equal(
      "#{c_header}*(pointer) = 1;\n  return 0;\n}",
      MindFreak.to_c(program)
    )
    # User tape
    tape = [0,0]
    assert_equal(
      "#{c_header(2, tape.join(', '))}*(pointer) = 1;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  def test_to_c_sum
    program = SUM.dup
    assert_nil(MindFreak.check(program))
    # Default tape
    assert_equal(
      "#{c_header}return 0;\n}",
      MindFreak.to_c(program)
    )
    # User tape
    tape = [5,10]
    assert_equal(
      "#{c_header(2, tape.join(', '))}*(pointer+1) += *(pointer);\n  *(pointer) = 0;\n  return 0;\n}",
      MindFreak.to_c(program, tape)
    )
  end

  def test_to_c_read_consecutive
    program = ',,,,,'
    assert_nil(MindFreak.check(program))
    eof_zero = "int c;\n  for(unsigned int i = 4; i--;) getchar();\n  (*(pointer)) = (c = getchar()) != EOF ? c : 0;\n  return 0;\n}"
    eof_minus_one = "for(unsigned int i = 4; i--;) getchar();\n  (*(pointer)) = getchar();\n  return 0;\n}"
    eof_unchanged = "int c;\n  for(unsigned int i = 4; i--;) getchar();\n  if((c = getchar()) != EOF) (*(pointer)) = c;\n  return 0;\n}"
    # Default tape
    assert_equal(
      c_header << eof_zero,
      MindFreak.to_c(program)
    )
    assert_equal(
      c_header << eof_minus_one,
      MindFreak.to_c(program, MindFreak::TAPE_DEFAULT_SIZE, -1)
    )
    assert_equal(
      c_header << eof_unchanged,
      MindFreak.to_c(program, MindFreak::TAPE_DEFAULT_SIZE, nil)
    )
    # User tape
    tape = [0,0]
    assert_equal(
      c_header(2, tape.join(', ')) << eof_zero,
      MindFreak.to_c(program, tape)
    )
    assert_equal(
      c_header(2, tape.join(', ')) << eof_minus_one,
      MindFreak.to_c(program, tape, -1)
    )
    assert_equal(
      c_header(2, tape.join(', ')) << eof_unchanged,
      MindFreak.to_c(program, tape, nil)
    )
  end

  def test_to_c_infinite_loop
    program = '[]'
    assert_nil(MindFreak.check(program))
    # Default tape
    assert_equal(
      "#{c_header}return 0;\n}",
      MindFreak.to_c(program)
    )
    # User tape
    assert_equal(
      "#{c_header(1, '1')}while(*pointer){\n  }\n  return 0;\n}",
      MindFreak.to_c(program, [1])
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
        [MindFreak::JUMPBACK, 0]
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
        [MindFreak::JUMPBACK,   0]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::INCREMENT, 0, nil, true]
      ],
      MindFreak.optimize(bytecode)
    )
    old_bytecode = [
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
    ]
    assert_equal(
      [
        [MindFreak::INCREMENT, 0, nil, true],
        [MindFreak::MULTIPLY,  1, nil, nil, 1],
        [MindFreak::INCREMENT, 0, nil, true],
      ],
      MindFreak.optimize(old_bytecode)
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

  def test_bytecode_jump_with_offset
    # Bytecode uses [instruction, argument]
    bytecode = MindFreak.bytecode('>>[>]')
    assert_equal(
      [
        [MindFreak::FORWARD,    2],
        [MindFreak::JUMP,       3],
        [MindFreak::FORWARD,    1],
        [MindFreak::JUMPBACK,   1]
      ],
      bytecode
    )
    # Optimized bytecode uses [instruction, argument, offset, assign, multiplier]
    assert_equal(
      [
        [MindFreak::JUMP,       1, 2],
        [MindFreak::JUMPBACK,   0, 1]
      ],
      MindFreak.optimize(bytecode)
    )
  end

  def test_bytecode_hello_world
    program = HELLO_WORLD.dup
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
  end

  def test_bytecode_mandelbrot
    filename = 'mandelbrot.bf'
    file_c = "#{filename}.c"
    file_exe = "#{filename}.exe"
    # Check bytecode size
    program = File.read(filename)
    assert_nil(MindFreak.check(program))
    bytecode = MindFreak.bytecode(program)
    assert_equal(4115, bytecode.size)
    assert_equal(1645, MindFreak.optimize(bytecode).size)
    # Compare output
    File.write(file_c, MindFreak.to_c(program))
    ['gcc', 'clang'].each {|cc| assert_equal(MANDELBROT, `./#{file_exe}`) if system("#{cc} #{file_c} -o #{file_exe} -O2 -s")}
  ensure
    File.delete(file_c) if File.exist?(file_c)
    File.delete(file_exe) if File.exist?(file_exe)
  end

  MANDELBROT = 
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
'
end