#!/usr/bin/env ruby
#-----------------------------------------------
# MindFreak
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# BrainFuck interpreter
#-----------------------------------------------

module MindFreak
  extend self

  attr_reader :pointer
  attr_accessor :input, :output, :debug

  HELP = "MindFreak filename.bf [mode=interpreter|bytecode|bytecode2|rb|c] [bounds=#{TAPE_DEFAULT_SIZE = 500}]"

  INCREMENT = ?+.ord
  DECREMENT = ?-.ord
  FORWARD   = ?>.ord
  BACKWARD  = ?<.ord
  WRITE     = ?..ord
  READ      = ?,.ord
  JUMP      = ?[.ord
  JUMPBACK  = ?].ord

  MULTIPLY  = ?*.ord

  @input  = STDIN
  @output = STDOUT

  #-----------------------------------------------
  # Check
  #-----------------------------------------------

  def check(program)
    # Remove comments and verify balanced brackets
    control = 0
    program.delete!('^-+><.,[]')
    program.each_byte {|c|
      if c == JUMP then control += 1
      elsif c == JUMPBACK and (control -= 1) < 0 then raise 'Unexpected ] found'
      end
    }
    raise 'Expected ]' unless control.zero?
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def run_interpreter(program, tape)
    program_size = program.size
    program_counter = -1
    @pointer = 0
    # Intepreter
    until (program_counter += 1) == program_size
      case program[program_counter]
      when ?+ # Increment
        tape[@pointer] += 1
      when ?- # Decrement
        tape[@pointer] -= 1
      when ?> # Forward
        @pointer += 1
      when ?< # Backward
        @pointer -= 1
      when ?. # Write
        @output.putc(tape[@pointer])
      when ?, # Read
        tape[@pointer] = @input.getbyte.to_i
      when ?[ # Jump if zero
        if tape[@pointer].zero?
          control = 1
          until control.zero?
            case program[program_counter += 1]
            when ?[ then control += 1
            when ?] then control -= 1
            end
          end
        end
      when ?] # Return unless zero
        unless tape[@pointer].zero?
          control = -1
          until control.zero?
            case program[program_counter -= 1]
            when ?[ then control += 1
            when ?] then control -= 1
            end
          end
        end
      else raise "Unknown instruction: #{program[program_counter]} at position #{program_counter}"
      end
    end
  end

  #-----------------------------------------------
  # Run bytecode
  #-----------------------------------------------

  def run_bytecode(program, tape)
    # Bytecode interpreter does not support optimizations
    bytecode = bytecode(program)
    program_size = bytecode.size
    program_counter = -1
    @pointer = 0
    # Execute
    until (program_counter += 1) == program_size
      c, arg = bytecode[program_counter]
      case c
      when INCREMENT # Tape
        tape[@pointer] += arg
      when FORWARD # Pointer
        @pointer += arg
      when WRITE # Write
        arg > 1 ? @output.print(tape[@pointer].chr * arg) : @output.putc(tape[@pointer])
      when READ # Read
        @input.read(arg.pred)
        tape[@pointer] = @input.getbyte.to_i
      when JUMP # Jump if zero
        program_counter = arg if tape[@pointer].zero?
      when JUMPBACK # Return unless zero
        program_counter = arg unless tape[@pointer].zero?
      else raise "Unknown bytecode: #{c} at position #{program_counter}"
      end
    end
  end

  #-----------------------------------------------
  # Run bytecode2
  #-----------------------------------------------

  def run_bytecode2(program, tape)
    # Bytecode2 interpreter support optimizations
    bytecode = optimize(bytecode(program), tape[0] == 0)
    program_size = bytecode.size
    program_counter = -1
    @pointer = 0
    # Execute
    until (program_counter += 1) == program_size
      c, arg, offset, assign, multiplier = bytecode[program_counter]
      case c
      when INCREMENT # Tape
        if assign
          tape[offset ? offset + @pointer : @pointer] = arg
        else
          tape[offset ? offset + @pointer : @pointer] += arg
        end
      when FORWARD # Pointer
        @pointer += arg
      when WRITE # Write
        c = tape[offset ? offset + @pointer : @pointer]
        arg > 1 ? @output.print(c.chr * arg) : @output.putc(c)
      when READ # Read
        @input.read(arg.pred)
        tape[offset ? offset + @pointer : @pointer] = @input.getbyte.to_i
      when JUMP # Jump if zero
        program_counter = arg if tape[@pointer].zero?
      when JUMPBACK # Return unless zero
        program_counter = arg unless tape[@pointer].zero?
      when MULTIPLY # Multiplication
        offset = offset ? offset + @pointer : @pointer
        if assign
          tape[arg + offset] = tape[offset] * multiplier
        else
          tape[arg + offset] += tape[offset] * multiplier
        end
      else raise "Unknown bytecode: #{c} at position #{program_counter}"
      end
    end
  end

  #-----------------------------------------------
  # to Ruby
  #-----------------------------------------------

  def to_ruby(program, tape = nil, input = 'STDIN', output = 'STDOUT')
    # Tape definition
    code = tape.instance_of?(Array) || tape.instance_of?(Hash) ? '' : tape == 0 ? "tape = Hash.new(0)\npointer = 0" : "tape = Array.new(#{tape || TAPE_DEFAULT_SIZE},0)\npointer = 0"
    indent = "\n"
    looped = false
    pointer = 0
    # Match bytecode
    optimize(bytecode(program), !code.empty? || tape[0] == 0).each {|c,arg,offset,assign,multiplier|
      case c
      when INCREMENT # Tape
        code << "#{indent}tape[#{looped ? "pointer#{"+#{offset}" if offset}" : offset ? offset + pointer : pointer}] #{'+' unless assign}= #{arg}"
      when FORWARD # Pointer
        code << (looped ? "#{indent}pointer += #{arg}" : "#{indent}pointer = #{pointer += arg}")
      when WRITE # Write
        c = "tape[#{looped ? "pointer#{"+#{offset}" if offset}" : offset ? offset + pointer : pointer}]"
        code << "#{indent}#{arg > 1 ? "#{output}.print #{c}.chr * #{arg}" : "#{output}.putc #{c}"}"
      when READ # Read
        code << "#{indent}#{input}.read(#{arg.pred})" if arg > 1
        code << "#{indent}tape[#{looped ? "pointer#{"+#{offset}" if offset}" : offset ? offset + pointer : pointer}] = #{input}.getbyte.to_i"
      when JUMP # Jump if zero
        looped = true
        code << "#{indent}until tape[pointer].zero?"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(-2,2)
        code << "#{indent}end"
      when MULTIPLY # Multiplication
        if looped
          code << "#{indent}tape[pointer+#{offset ? offset + arg : arg}] #{'+' unless assign}= tape[pointer#{"+#{offset}" if offset}]#{" * #{multiplier}" if multiplier != 1}"
        else
          code << "#{indent}tape[#{offset ? offset + pointer + arg : pointer + arg}] #{'+' unless assign}= tape[#{offset ? offset + pointer : pointer}]#{" * #{multiplier}" if multiplier != 1}"
        end
      else raise "Unknown bytecode: #{c}"
      end
    }
    code
  end

  #-----------------------------------------------
  # to C
  #-----------------------------------------------

  def to_c(program, tape = nil, eof = 0, type = 'unsigned int')
    if not tape or (tape_size = tape.size).zero?
      tape_size = TAPE_DEFAULT_SIZE
      puts "C mode requires a bounded tape, using #{tape_size} cells" if @debug
    end
    eof_variable = nil
    code = ''
    indent = "\n  "
    # Match bytecode
    optimize(bytecode(program), tape && tape[0] == 0).each {|c,arg,offset,assign,multiplier|
      case c
      when INCREMENT # Tape
        code << "#{indent}*(pointer#{"+#{offset}" if offset}) #{'+' unless assign}= #{arg};"
      when FORWARD # Pointer
        code << "#{indent}pointer += #{arg};"
      when WRITE # Write
        c = "putchar(*(pointer#{"+#{offset}" if offset}));"
        code << "#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i; --i) #{c}" : c}"
      when READ # Read
        code << "#{indent}for(unsigned int i = #{arg.pred}; i; --i) getchar();" if arg > 1
        if eof == -1
          code << "#{indent}(*(pointer#{"+#{offset}" if offset})) = getchar();"
        else
          code << "#{indent}c = getchar();#{indent}(*(pointer#{"+#{offset}" if offset})) = c == EOF ? #{eof} : c;"
          eof_variable ||= "\n  int c;"
        end
      when JUMP # Jump if zero
        code << "#{indent}while(*pointer){"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(-2,2)
        code << "#{indent}}"
      when MULTIPLY # Multiplication
        code << "#{indent}*(pointer+#{offset ? offset + arg : arg}) #{'+' unless assign}= *(pointer#{"+#{offset}" if offset})#{" * #{multiplier}" if multiplier != 1};"
      else raise "Unknown bytecode: #{c}"
      end
    }
    "#include <stdio.h>\nint main(){\n  #{type} tape[#{tape_size}] = {0}, *pointer = tape;#{eof_variable}#{code}\n  return 0;\n}"
  end

  #-----------------------------------------------
  # Bytecode
  #-----------------------------------------------

  def bytecode(program)
    bytecode = []
    jump_stack = []
    last = index = 0
    # Compress
    program.each_byte {|c|
      # Repeated instruction
      if c == last
        if (bytecode.last[1] += 1).zero?
          bytecode.pop
          last = bytecode.last && bytecode.last.first < JUMP ? bytecode.last.first : 0
          index -= 1
        end
      # Disguised repeated instruction
      elsif (c == DECREMENT and last == INCREMENT) or (c == BACKWARD and last == FORWARD)
        if (bytecode.last[1] -= 1).zero?
          bytecode.pop
          last = bytecode.last && bytecode.last.first < JUMP ? bytecode.last.first : 0
          index -= 1
        end
      else
        # New simple instruction
        if c < JUMP
          bytecode << case c
          when DECREMENT then [last = INCREMENT, -1]
          when BACKWARD then [last = FORWARD, -1]
          else [last = c, 1]
          end
        # Jump
        else
          last = 0
          if c == JUMP
            bytecode << [JUMP]
            jump_stack << index
          else
            # Jump program counter to index, only works for bytecode
            bytecode << [JUMPBACK, jump_stack.last]
            bytecode[jump_stack.pop] << index
          end
        end
        index += 1
      end
    }
    puts "Bytecode size: #{bytecode.size}" if @debug
    bytecode
  end

  #-----------------------------------------------
  # Optimize
  #-----------------------------------------------

  def optimize(bytecode, blank_tape = false)
    # Dead code elimination
    bytecode.shift(bytecode[0].last+1) if blank_tape and bytecode[0].first == JUMP and not bytecode[1].first == INCREMENT && bytecode[2].first == JUMPBACK
    clear = [INCREMENT, 0, nil, true]
    memory = Hash.new(0)
    i = -1
    while (i += 1) < bytecode.size
      case bytecode[i].first
      # Clear [-] [+] or Assign [-]+ [+]-
      when JUMP
        if bytecode[i.succ].first == INCREMENT and bytecode[i+2].first == JUMPBACK
          # Assign
          if bytecode[i+3] and bytecode[i+3].first == INCREMENT
            bytecode.slice!(i,3)
            bytecode[i].push(nil, true)
          # Clear
          else
            bytecode.slice!(i,2)
            bytecode[i] = clear
          end
          # Previous increment operation is redundant
          bytecode.delete_at(i -= 1) if i != 0 and bytecode[i.pred].first == INCREMENT
        else start = i
        end
      # Multiplication [->+<]
      when JUMPBACK
        next unless start
        # Extract data
        pointer = 0
        start.succ.upto(i.pred) {|k|
          if (k = bytecode[k]).first == FORWARD
            pointer += k[1]
          elsif k.first == INCREMENT and not k[3]
            memory[pointer] += k[1]
          else
            pointer = start = nil
            break
          end
        }
        # Apply if pointer ends at same point and memory[0] is a counter
        if pointer == 0 and memory.delete(0) == -1
          bytecode[start..i] = memory.map {|key,value| [MULTIPLY, key, nil, nil, value]}
          i = start + memory.size
          if k = bytecode[i] and k.first == INCREMENT
            k[3] = true
            i += 1
          else bytecode.insert(i, clear)
          end
        end
        memory.clear
      end
    end
    jump_stack = []
    i = -1
    while (i += 1) < bytecode.size
      case bytecode[i].first
      # Offset >+< <.>
      when FORWARD
        if next_inst = bytecode[i.succ]
          if next_inst.first < JUMP
            # Original instruction uses offset
            offset = bytecode[i]
            (bytecode[i] = next_inst.equal?(clear) ? clear.dup : next_inst)[2] = offset[1]
            # Push offset to next forward if they do not nullify
            if bytecode[i+2] and bytecode[i+2].first == FORWARD
              bytecode.delete_at(i+2) if (bytecode[i+2][1] += offset[1]).zero?
              bytecode.delete_at(i.succ)
            # Swap forward with original instruction
            else bytecode[i.succ] = offset
            end
            i -= 1 if next_inst.first == MULTIPLY
          end
        # Remove last forward
        else bytecode.pop
        end
      # Rebuild jump index argument, only works for bytecode
      when JUMP then jump_stack << i
      when JUMPBACK then bytecode[bytecode[i][1] = jump_stack.pop][1] = i
      # Multiplication assignment
      when MULTIPLY
        if i > 0 and (a = bytecode[i.pred]).first == INCREMENT and a[1].zero? and a[3] and a[2] == (b = bytecode[i])[1] + b[2].to_i
          b[3] = true
          bytecode.delete_at(i -= 1)
        end
      end
    end
    puts "Bytecode optimized to size: #{bytecode.size}" if @debug
    bytecode
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    # Help
    if ARGV.empty? or ARGV.first == '-h'
      puts MindFreak::HELP
    else
      # Input
      filename = ARGV[0]
      mode = ARGV[1] || 'interpreter'
      # Tape size
      bounds = ARGV[2] ? ARGV[2].to_i : MindFreak::TAPE_DEFAULT_SIZE
      tape = bounds > 0 ? Array.new(bounds, 0) : Hash.new(0)
      # Setup
      program = IO.read(filename)
      MindFreak.check(program)
      MindFreak.debug = true
      # Keep source and executables
      keep = true
      # Select mode
      case mode
      when 'interpreter'
        puts 'Interpreter Mode'
        t = Time.now.to_f
        MindFreak.run_interpreter(program, tape)
        puts "\nTime: #{Time.now.to_f - t}s", 'Tape:', tape.inspect
      when 'bytecode'
        puts 'Bytecode Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode(program, tape)
        puts "\nTime: #{Time.now.to_f - t}s", 'Tape:', tape.inspect
      when 'bytecode2'
        puts 'Bytecode2 Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode2(program, tape)
        puts "\nTime: #{Time.now.to_f - t}s", 'Tape:', tape.inspect
      when 'rb'
        puts 'Ruby Mode'
        t = Time.now.to_f
        pointer = 0
        eval(code = MindFreak.to_ruby(program, tape))
        puts "\nTime: #{Time.now.to_f - t}s"
        IO.write("#{filename}.rb", code) if keep
      when 'c'
        puts 'C Mode', 'Compiling'
        # Compile
        file_c = "#{filename}.c"
        file_exe = "./#{filename}.exe"
        t = Time.now.to_f
        IO.write(file_c, MindFreak.to_c(program, tape))
        if system("gcc #{file_c} -o #{file_exe} -O2 -s")
          puts "Compilation time: #{Time.now.to_f - t}s"
          # Execute
          t = Time.now.to_f
          system(file_exe)
          puts "\nTime: #{Time.now.to_f - t}s"
          File.delete(file_c, file_exe) unless keep
        end
      else raise 'Mode not found'
      end
    end
  rescue Interrupt
    case mode
    when 'interpreter', 'bytecode', 'bytecode2'
      puts "\nTape: #{tape}", "Pointer: #{MindFreak.pointer}"
    when 'rb'
      puts "\nTape: #{tape}", "Pointer: #{pointer}"
    end
  rescue
    puts $!, $@
  end
end