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
  attr_writer :debug

  HELP = "MindFreak filename.bf [mode=interpreter|bytecode|bytecode2|rb|c] [bounds=#{TAPE_DEFAULT_SIZE = 500}] [EOF=0|-1|any integer|unchanged]"

  INCREMENT = ?+.ord
  DECREMENT = ?-.ord
  FORWARD   = ?>.ord
  BACKWARD  = ?<.ord
  WRITE     = ?..ord
  READ      = ?,.ord
  JUMP      = ?[.ord
  JUMPBACK  = ?].ord

  MULTIPLY  = ?*.ord

  #-----------------------------------------------
  # Check
  #-----------------------------------------------

  def check(program)
    # Remove comments and verify balanced brackets
    control = 0
    program.delete!('^-+><.,[]')
    program.delete('^[]').each_byte {|b| raise 'Unexpected ] found' if (control += 92 - b) < 0}
    raise 'Expected ]' if control != 0
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def run_interpreter(program, tape, eof = 0, input = STDIN, output = STDOUT)
    program_size = program.size
    program_counter = -1
    @pointer = 0
    # Interpreter
    until (program_counter += 1) == program_size
      case program.getbyte(program_counter)
      when INCREMENT
        tape[@pointer] += 1
      when DECREMENT
        tape[@pointer] -= 1
      when FORWARD
        @pointer += 1
      when BACKWARD
        @pointer -= 1
      when WRITE
        output.putc(tape[@pointer])
      when READ
        tape[@pointer] = input.getbyte || eof || next
      when JUMP
        if tape[@pointer] == 0
          control = 1
          nil until (b = program.getbyte(program_counter += 1)) >= JUMP and (control += 92 - b) == 0
        end
      when JUMPBACK
        if tape[@pointer] != 0
          control = -1
          nil until (b = program.getbyte(program_counter -= 1)) >= JUMP and (control += 92 - b) == 0
        end
      else raise "Unknown instruction: #{program[program_counter]} at position #{program_counter}"
      end
    end
  end

  #-----------------------------------------------
  # Run bytecode
  #-----------------------------------------------

  def run_bytecode(program, tape, eof = 0, input = STDIN, output = STDOUT)
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
        arg > 1 ? output.print(tape[@pointer].chr * arg) : output.putc(tape[@pointer])
      when READ # Read
        input.read(arg - 1)
        tape[@pointer] = input.getbyte || eof || next
      when JUMP # Jump if zero
        program_counter = arg if tape[@pointer] == 0
      when JUMPBACK # Return unless zero
        program_counter = arg if tape[@pointer] != 0
      else raise "Unknown bytecode: #{c} at position #{program_counter}"
      end
    end
  end

  #-----------------------------------------------
  # Run bytecode2
  #-----------------------------------------------

  def run_bytecode2(program, tape, eof = 0, input = STDIN, output = STDOUT)
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
        arg > 1 ? output.print(c.chr * arg) : output.putc(c)
      when READ # Read
        input.read(arg - 1)
        tape[offset ? offset + @pointer : @pointer] = input.getbyte || eof || next
      when JUMP # Jump if zero
        program_counter = arg if tape[@pointer] == 0
      when JUMPBACK # Return unless zero
        program_counter = arg if tape[@pointer] != 0
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

  def to_ruby(program, tape = TAPE_DEFAULT_SIZE, eof = 0, input = 'STDIN', output = 'STDOUT')
    # Tape definition
    code = tape.instance_of?(Array) || tape.instance_of?(Hash) ? '' : tape > 0 ? "tape = Array.new(#{tape},0)\npointer = 0" : "tape = Hash.new(0)\npointer = 0"
    indent = "\n"
    pointer = 0
    # Match bytecode
    optimize(bytecode(program), !code.empty? || tape[0] == 0).each {|c,arg,offset,assign,multiplier|
      case c
      when INCREMENT # Tape
        code << "#{indent}tape[#{pointer ? offset ? offset + pointer : pointer : "pointer#{"+#{offset}" if offset}"}] #{'+' unless assign}= #{arg}"
      when FORWARD # Pointer
        code << (pointer ? "#{indent}pointer = #{pointer += arg}" : "#{indent}pointer += #{arg}")
      when WRITE # Write
        c = "tape[#{pointer ? offset ? offset + pointer : pointer : "pointer#{"+#{offset}" if offset}"}]"
        code << "#{indent}#{arg > 1 ? "#{output}.print #{c}.chr * #{arg}" : "#{output}.putc #{c}"}"
      when READ # Read
        code << "#{indent}#{input}.read(#{arg - 1})" if arg > 1
        if eof
          code << "#{indent}tape[#{pointer ? offset ? offset + pointer : pointer : "pointer#{"+#{offset}" if offset}"}] = #{input}.getbyte || #{eof}"
        else
          code << "#{indent}c = #{input}.getbyte and tape[#{pointer ? offset ? offset + pointer : pointer : "pointer#{"+#{offset}" if offset}"}] = c"
        end
      when JUMP # Jump if zero
        pointer = nil
        code << "#{indent}while tape[pointer] != 0"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(-2,2)
        code << "#{indent}end"
      when MULTIPLY # Multiplication
        if pointer
          code << "#{indent}tape[#{pointer + (offset ? offset + arg : arg)}] #{'+' unless assign}= tape[#{offset ? offset + pointer : pointer}]#{" * #{multiplier}" if multiplier != 1}"
        else
          code << "#{indent}tape[pointer+#{offset ? offset + arg : arg}] #{'+' unless assign}= tape[pointer#{"+#{offset}" if offset}]#{" * #{multiplier}" if multiplier != 1}"
        end
      else raise "Unknown bytecode: #{c}"
      end
    }
    code
  end

  #-----------------------------------------------
  # to C
  #-----------------------------------------------

  def to_c(program, tape = TAPE_DEFAULT_SIZE, eof = 0, type = 'unsigned int')
    case tape
    when Integer
      tape_str = '0'
      tape_size = tape
      tape = [0]
    when Array
      tape_str = tape.join(', ')
      tape_size = tape.size
    else tape_size = 0
    end
    raise 'C mode expects a non-empty bounded tape' if tape_size == 0
    eof_variable = nil
    code = ''
    indent = "\n  "
    # Match bytecode
    optimize(bytecode(program), tape[0] == 0).each {|c,arg,offset,assign,multiplier|
      case c
      when INCREMENT # Tape
        code << "#{indent}*(pointer#{"+#{offset}" if offset}) #{'+' unless assign}= #{arg};"
      when FORWARD # Pointer
        code << "#{indent}pointer += #{arg};"
      when WRITE # Write
        c = "putchar(*(pointer#{"+#{offset}" if offset}));"
        code << "#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i--;) #{c}" : c}"
      when READ # Read
        code << "#{indent}for(unsigned int i = #{arg-1}; i--;) getchar();" if arg > 1
        case eof
        when nil
          code << "#{indent}if((c = getchar()) != EOF) (*(pointer#{"+#{offset}" if offset})) = c;"
          eof_variable ||= "\n  int c;"
        when -1
          code << "#{indent}(*(pointer#{"+#{offset}" if offset})) = getchar();"
        else
          code << "#{indent}(*(pointer#{"+#{offset}" if offset})) = (c = getchar()) != EOF ? c : #{eof};"
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
    "#include <stdio.h>\nint main(){\n  #{type} tape[#{tape_size}] = {#{tape_str}}, *pointer = tape;#{eof_variable}#{code}\n  return 0;\n}"
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
        if (bytecode[-1][1] += 1) == 0
          bytecode.pop
          last = bytecode[-1] && bytecode[-1][0] < JUMP ? bytecode[-1][0] : 0
          index -= 1
        end
      # Disguised repeated instruction
      elsif (c == DECREMENT and last == INCREMENT) or (c == BACKWARD and last == FORWARD)
        if (bytecode[-1][1] -= 1) == 0
          bytecode.pop
          last = bytecode[-1] && bytecode[-1][0] < JUMP ? bytecode[-1][0] : 0
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
        else
          # Jump
          if c == JUMP
            bytecode << [JUMP]
            jump_stack << index
          # Dead jump
          elsif (last = jump_stack.pop) > 0 and bytecode[last-1][0] == JUMPBACK
            bytecode.pop(index - last)
            index = last - 1
          # Jump program counter to index
          else
            bytecode << [JUMPBACK, last]
            bytecode[last] << index
          end
          last = 0
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
    bytecode.shift(bytecode[0][1]+1) if blank_tape and bytecode[0] and bytecode[0][0] == JUMP and bytecode[1][0] != INCREMENT || bytecode[2][0] != JUMPBACK
    clear = [INCREMENT, 0, nil, true]
    memory = Hash.new(0)
    i = -1
    while (i += 1) < bytecode.size
      case bytecode[i][0]
      # Clear [-] [+] or Assign [-]+ [+]-
      when JUMP
        if bytecode[i+1][0] == INCREMENT and bytecode[i+2][0] == JUMPBACK
          # Assign
          if bytecode[i+3] and bytecode[i+3][0] == INCREMENT
            bytecode.slice!(i,3)
            bytecode[i].push(nil, true)
          # Clear
          else
            bytecode.slice!(i,2)
            bytecode[i] = clear
          end
          # Previous increment operation is redundant
          bytecode.delete_at(i -= 1) if i != 0 and bytecode[i-1][0] == INCREMENT
        else start = i
        end
      # Multiplication [->+<]
      when JUMPBACK
        next unless start
        # Extract data
        pointer = 0
        (start+1).upto(i-1) {|k|
          if (k = bytecode[k])[0] == FORWARD
            pointer += k[1]
          elsif k[0] == INCREMENT and not k[3]
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
          if k = bytecode[i] and k[0] == INCREMENT
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
      case bytecode[i][0]
      # Offset >+< <.>
      when FORWARD
        if next_inst = bytecode[i+1]
          if next_inst[0] < JUMP
            # Original instruction uses offset
            offset = bytecode[i]
            (bytecode[i] = next_inst.equal?(clear) ? clear.dup : next_inst)[2] = offset[1]
            # Push offset to next forward if they do not nullify
            if bytecode[i+2] and bytecode[i+2][0] == FORWARD
              bytecode.delete_at(i+2) if (bytecode[i+2][1] += offset[1]) == 0
              bytecode.delete_at(i+1)
            # Swap forward with original instruction
            else bytecode[i+1] = offset
            end
            i -= 1 if next_inst[0] == MULTIPLY
          end
        # Remove last forward
        else bytecode.pop
        end
      # Rebuild jump index argument
      when JUMP then jump_stack << i
      when JUMPBACK then bytecode[bytecode[i][1] = jump_stack.pop][1] = i
      # Multiplication assignment
      when MULTIPLY
        if i > 0 and (a = bytecode[i-1])[0] == INCREMENT and a[1] == 0 and a[3] and a[2] == (b = bytecode[i])[1] + b[2].to_i
          b[3] = true
          bytecode.delete_at(i -= 1)
        end
      end
    end
    puts "Optimized bytecode size: #{bytecode.size}" if @debug
    bytecode
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    # Help
    if ARGV.empty? or ARGV[0] == '-h'
      puts MindFreak::HELP
    else
      # Options
      filename = ARGV[0]
      mode = ARGV[1] || 'interpreter'
      bounds = ARGV[2] ? ARGV[2].to_i : MindFreak::TAPE_DEFAULT_SIZE
      tape = bounds > 0 ? Array.new(bounds, 0) : Hash.new(0)
      eof = ARGV[3].to_i if ARGV[3] != 'unchanged'
      # Setup
      program = File.read(filename)
      MindFreak.check(program)
      MindFreak.debug = true
      # Keep source and executables
      keep = true
      # Select mode
      case mode
      when 'interpreter'
        puts 'Interpreter Mode'
        t = Time.now.to_f
        MindFreak.run_interpreter(program, tape, eof)
        puts "\nTime: #{Time.now.to_f - t}s", 'Tape:', tape.inspect
      when 'bytecode'
        puts 'Bytecode Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode(program, tape, eof)
        puts "\nTime: #{Time.now.to_f - t}s", 'Tape:', tape.inspect
      when 'bytecode2'
        puts 'Bytecode2 Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode2(program, tape, eof)
        puts "\nTime: #{Time.now.to_f - t}s", 'Tape:', tape.inspect
      when 'rb'
        puts 'Ruby Mode'
        t = Time.now.to_f
        pointer = 0
        eval(code = MindFreak.to_ruby(program, tape, eof))
        puts "\nTime: #{Time.now.to_f - t}s"
        File.write("#{filename}.rb", code) if keep
      when 'c'
        puts 'C Mode', 'Compiling'
        # Compile
        file_c = "#{filename}.c"
        file_exe = "./#{filename}.exe"
        t = Time.now.to_f
        File.write(file_c, MindFreak.to_c(program, bounds, eof))
        if ['gcc', 'clang'].any? {|cc| system("#{cc} #{file_c} -o #{file_exe} -O2 -s")}
          puts "Compilation time: #{Time.now.to_f - t}s"
          # Execute
          t = Time.now.to_f
          system(file_exe)
          puts "\nTime: #{Time.now.to_f - t}s"
          File.delete(file_c, file_exe) unless keep
        else abort('C compiler not found')
        end
      else abort("Unknown mode: #{mode}")
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