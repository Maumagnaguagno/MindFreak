#!/usr/bin/env ruby
#-----------------------------------------------
# MindFreak
#-----------------------------------------------
# Mau Magnaguagno
#-----------------------------------------------
# Use MindFreak.rb
#-----------------------------------------------
# BrainFuck interpreter
#-----------------------------------------------
# Oct 2013
# - Created
# - Unbounded cell value
# - Bounded ou unbounded tape
# - Interpret +-><.,[] as commands, the rest as comments
# - Check brackets before execution
# - Output tape when interrupted
# - Object oriented style
# - Bytecode mode
# - Ruby Mode
# Dec 2013
# - Optimizations
# Feb 2015
# - C mode
# Sep 2015
# - File keep optional
# - Improved 1.8.7 compatibility
# Oct 2015
# - Module based
# - Tape input
# - Less instance variables
# - Select IO
# - Multiplication
# - Ruby and C methods generate code instead of execution
# - Multiplication optimization
# - Bytecode2 interpreter
# - Removed program and tape from instance variables
# - Removed setup
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
  # Check program
  #-----------------------------------------------

  def check_program(program)
    # Remove comments and check balanced brackets
    control = 0
    program.gsub!(/[^-+><.,\[\]]/,'')
    program.each_byte {|c|
      if c == JUMP then control += 1
      elsif c == JUMPBACK and (control -= 1) < 0 then raise 'Unexpected ] found'
      end
    }
    raise 'Expected [' unless control.zero?
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def run_interpreter(program, tape)
    program_size = program.size
    program_counter = -1
    control = @pointer = 0
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
        tape[@pointer] = @input.getbyte
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
    bytecode = make_bytecode(program)
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
        arg.pred.times {@input.getbyte}
        tape[@pointer] = @input.getbyte
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
    bytecode = optimize_bytecode(make_bytecode(program))
    program_size = bytecode.size
    program_counter = -1
    @pointer = 0
    # Execute
    until (program_counter += 1) == program_size
      c, arg, offset, set_multiplier = bytecode[program_counter]
      case c
      when INCREMENT # Tape
        if set_multiplier
          tape[offset ? @pointer + offset : @pointer] = arg
        else
          tape[offset ? @pointer + offset : @pointer] += arg
        end
      when FORWARD # Pointer
        @pointer += arg
      when WRITE # Write
        c = tape[offset ? @pointer + offset : @pointer]
        arg > 1 ? @output.print(c.chr * arg) : @output.putc(c)
      when READ # Read
        arg.pred.times {@input.getbyte}
        tape[offset ? @pointer + offset : @pointer] = @input.getbyte
      when JUMP # Jump if zero
        program_counter = arg if tape[@pointer].zero?
      when JUMPBACK # Return unless zero
        program_counter = arg unless tape[@pointer].zero?
      when MULTIPLY # Multiplication
        tape[@pointer + (offset ? arg + offset : arg)] += tape[offset ? @pointer + offset : @pointer] * set_multiplier
      else raise "Unknown bytecode: #{c} at position #{program_counter}"
      end
    end
  end

  #-----------------------------------------------
  # to Ruby
  #-----------------------------------------------

  def to_ruby(program, tape = nil, input = 'STDIN', output = 'STDOUT')
    # Tape definition
    code = tape ? tape.empty? ? "tape = Hash.new(0)\npointer = 0" : "tape = Array.new(#{tape.size},0)\npointer = 0" : ''
    indent = ''
    # Match bytecode
    optimize_bytecode(make_bytecode(program)).each {|c,arg,offset,set_multiplier|
      case c
      when INCREMENT # Tape
        code << "\n#{indent}tape[pointer#{"+#{offset}" if offset}] #{'+' unless set_multiplier}= #{arg}"
      when FORWARD # Pointer
        code << "\n#{indent}pointer += #{arg}"
      when WRITE # Write
        c = "tape[pointer#{"+#{offset}" if offset}]"
        code << "\n#{indent}#{arg > 1 ? "#{output}.print #{c}.chr * #{arg}" : "#{output}.putc #{c}"}"
      when READ # Read
        code << "\n#{indent}#{arg.pred}.times {#{input}.getbyte}" if arg > 1
        code << "\n#{indent}tape[pointer#{"+#{offset}" if offset}] = #{input}.getbyte"
      when JUMP # Jump if zero
        code << "\n#{indent}until tape[pointer].zero?"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(0,2)
        code << "\n#{indent}end"
      when MULTIPLY # Multiplication
        code << "\n#{indent}tape[pointer+#{offset ? arg + offset : arg}] += tape[pointer#{"+#{offset}" if offset}]#{" * #{set_multiplier}" if set_multiplier != 1}"
      else raise "Unknown bytecode: #{c}"
      end
    }
    code
  end

  #-----------------------------------------------
  # to C
  #-----------------------------------------------

  def to_c(program, tape, type = 'unsigned int')
    if (tape_size = tape.size).zero?
      tape_size = TAPE_DEFAULT_SIZE
      puts "C mode requires a bounded tape, using #{tape_size} cells" if @debug
    end
    # Header
    code = "#include <stdio.h>\nint main(){\n  #{type} tape[#{tape_size}] = {0};\n  #{type} *pointer = tape;"
    indent = '  '
    # Match bytecode
    optimize_bytecode(make_bytecode(program)).each {|c,arg,offset,set_multiplier|
      case c
      when INCREMENT # Tape
        code << "\n#{indent}*(pointer#{"+#{offset}" if offset}) #{'+' unless set_multiplier}= #{arg};"
      when FORWARD # Pointer
        code << "\n#{indent}pointer += #{arg};"
      when WRITE # Write
        c = "putchar(*(pointer#{"+#{offset}" if offset}));"
        code << "\n#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i; --i) #{c}" : c}"
      when READ # Read
        code << "\n#{indent}for(unsigned int i = #{arg.pred}; i; --i) getchar();" if arg > 1
        code << "\n#{indent}(*(pointer#{"+#{offset}" if offset})) = getchar();"
      when JUMP # Jump if zero
        code << "\n#{indent}while(*pointer){"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(0,2)
        code << "\n#{indent}}"
      when MULTIPLY # Multiplication
        code << "\n#{indent}*(pointer+#{offset ? arg + offset : arg}) += *(pointer#{"+#{offset}" if offset})#{" * #{set_multiplier}" if set_multiplier != 1};"
      else raise "Unknown bytecode: #{c}"
      end
    }
    code << "\n  return 0;\n}"
  end

  #-----------------------------------------------
  # Make bytecode
  #-----------------------------------------------

  def make_bytecode(program)
    bytecode = []
    jump_stack = []
    last = index = 0
    # Compress
    program.each_byte {|c|
      # Repeated instruction
      if c == last
        if (bytecode.last[1] += 1).zero?
          bytecode.pop
          last = bytecode.empty? ? 0 : bytecode.last.first
        end
      # Disguised repeated instruction
      elsif (c == DECREMENT and last == INCREMENT) or (c == BACKWARD and last == FORWARD)
        if (bytecode.last[1] -= 1).zero?
          bytecode.pop
          last = bytecode.empty? ? 0 : bytecode.last.first
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
            bytecode << [c]
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
  # Optimize bytecode
  #-----------------------------------------------

  def optimize_bytecode(bytecode)
    # Clear [-] [+] or set [-]+ [+]-
    clear = [INCREMENT, 0, nil, true]
    i = -1
    while (i += 1) < bytecode.size
      if bytecode[i].first == JUMP and bytecode[i.succ].first == INCREMENT and bytecode[i+2].first == JUMPBACK
        # Set
        if bytecode[i+3].first == INCREMENT
          bytecode[i] = [INCREMENT, bytecode[i+3][1], nil, true]
          bytecode.slice!(i.succ,3)
        # Clear
        else
          bytecode[i] = clear
          bytecode.slice!(i.succ,2)
        end
      end
    end
    # Multiplication [->+<]
    memory = Hash.new(0)
    i = -1
    while (i += 1) < bytecode.size
      # Start of loop
      if bytecode[i].first == JUMP
        j = i
        while (j += 1) < bytecode.size
          # Inner loop has been found
          if bytecode[j].first == JUMP
            i = j
          # End of loop
          elsif bytecode[j].first == JUMPBACK
            # Extract data
            pointer = 0
            i.succ.upto(j.pred) {|k|
              k = bytecode[k]
              if k.first == FORWARD
                pointer += k[1]
              elsif k.first == INCREMENT and not k[3]
                memory[pointer] += k[1]
              else
                pointer = nil
                break
              end
            }
            # Apply if pointer ends at same point and memory[0] is a counter
            if pointer == 0 and memory.delete(0) == -1
              bytecode[i..j] = memory.map {|key,value| [MULTIPLY, key, nil, value]} << clear
              i += memory.size.succ
              memory.clear
            else
              memory.clear
              break
            end
          end
        end
      end
    end
    # Offset >+< <.>
    i = -1
    while (i += 1) < bytecode.size.pred
      if (offset = bytecode[i]).first == FORWARD and (next_inst = bytecode[i.succ]).first < JUMP
        # Original instruction uses offset
        next_inst[2] = offset[1]
        bytecode[i] = next_inst.dup
        # Push offset to next forward if they do not nullify
        if bytecode[i+2] and bytecode[i+2].first == FORWARD
          bytecode.delete_at(i+2) if (bytecode[i+2][1] += offset[1]).zero?
          bytecode.delete_at(i.succ)
        # Swap forward with original instruction
        else bytecode[i.succ] = offset
        end
      end
    end
    # Remove last forwards
    bytecode.pop while bytecode.last.first == FORWARD
    # Rebuild jump arguments
    jump_stack = []
    i = -1
    while (i += 1) < bytecode.size
      if bytecode[i].first == JUMP
        jump_stack << i
      elsif bytecode[i].first == JUMPBACK
        # Jump program counter to index, only works for bytecode
        bytecode[i][1] = jump_stack.last
        bytecode[jump_stack.pop][1] = i
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
      MindFreak.check_program(program)
      MindFreak.debug = true
      # Keep source and executables
      keep = true
      # Select mode
      case mode
      when 'interpreter'
        puts 'Interpreter Mode'
        t = Time.now.to_f
        MindFreak.run_interpreter(program, tape)
        puts "\nTime: #{Time.now.to_f - t}s",'Tape:', tape.inspect
      when 'bytecode'
        puts 'Bytecode Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode(program, tape)
        puts "\nTime: #{Time.now.to_f - t}s",'Tape:', tape.inspect
      when 'bytecode2'
        puts 'Bytecode2 Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode2(program, tape)
        puts "\nTime: #{Time.now.to_f - t}s",'Tape:', tape.inspect
      when 'rb'
        puts 'Ruby Mode'
        t = Time.now.to_f
        pointer = 0
        eval(code = MindFreak.to_ruby(program))
        puts "\nTime: #{Time.now.to_f - t}s"
        IO.write("#{filename}.rb", code) if keep
      when 'c'
        puts 'C Mode', 'Compiling'
        # Compile
        file_c = "#{filename}.c"
        file_exe = "#{filename}.exe"
        t = Time.now.to_f
        IO.write(file_c, MindFreak.to_c(program, tape))
        system("gcc #{file_c} -o #{file_exe} -O2")
        puts "Compilation time: #{Time.now.to_f - t}s"
        # Execute
        t = Time.now.to_f
        system(file_exe)
        puts "\nTime: #{Time.now.to_f - t}s"
        File.delete(file_c, file_exe) unless keep
      else raise 'Mode not found'
      end
    end
  rescue Interrupt
    case mode
    when 'interpreter', 'bytecode', 'bytecode2'
      puts "\nTape: #{tape.inspect}", "Pointer: #{MindFreak.pointer}"
    when 'rb'
      puts "\nTape: #{tape.inspect}", "Pointer: #{pointer}"
    end
  rescue
    puts $!, $@
  end
end