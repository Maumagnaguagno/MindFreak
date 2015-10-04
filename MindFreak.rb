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
#-----------------------------------------------
# TODO
# - Debug System, verbose, step-by-step/interactive mode, breakpoint
#-----------------------------------------------

module MindFreak
  extend self

  attr_reader :program, :tape, :pointer, :input, :output
  attr_accessor :debug

  HELP = "MindFreak [filename=mandelbrot.bf] [mode=interpreter|bytecode|rb|c] [bounds=#{TAPE_DEFAULT_SIZE = 500}|<int>]"

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
  # Setup
  #-----------------------------------------------

  def setup(program, tape, check = true, input = STDIN, output = STDOUT)
    @program = program
    @tape = tape
    @input = input
    @output = output
    check_program(program) if check
  end

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

  def run_interpreter
    program_counter = control = @pointer = 0
    # Intepreter
    until program_counter == @program.size
      case @program[program_counter]
      when ?+ # Increment
        @tape[@pointer] += 1
      when ?- # Decrement
        @tape[@pointer] -= 1
      when ?> # Forward
        @pointer += 1
      when ?< # Backward
        @pointer -= 1
      when ?. # Write
        @output.putc(@tape[@pointer])
      when ?, # Read
        @tape[@pointer] = @input.getbyte
      when ?[ # Jump if zero
        if @tape[@pointer].zero?
          control = 1
          until control.zero?
            program_counter += 1
            case @program[program_counter]
            when ?[ then control += 1
            when ?] then control -= 1
            end
          end
        end
      when ?] # Return unless zero
        unless @tape[@pointer].zero?
          control = -1
          until control.zero?
            program_counter -= 1
            case @program[program_counter]
            when ?[ then control += 1
            when ?] then control -= 1
            end
          end
        end
      else raise "Unknown instruction: #{@program[program_counter]} at position #{program_counter}"
      end
      program_counter += 1
    end
  end

  #-----------------------------------------------
  # Run bytecode
  #-----------------------------------------------

  def run_bytecode
    # Bytecode interpreter does not support optimizations
    bytecode = make_bytecode(@program)
    program_counter = @pointer = 0
    # Execute
    until program_counter == bytecode.size
      c, arg = bytecode[program_counter]
      case c
      when INCREMENT # Tape
        @tape[@pointer] += arg
      when FORWARD # Pointer
        @pointer += arg
      when WRITE # Write
        arg.times {@output.putc(@tape[@pointer])}
      when READ # Read
        arg.times {@tape[@pointer] = @input.getbyte}
      when JUMP # Jump if zero
        program_counter = arg if @tape[@pointer].zero?
      when JUMPBACK # Return unless zero
        program_counter = arg unless @tape[@pointer].zero?
      else raise "Unknown bytecode: #{c} at position #{program_counter}"
      end
      program_counter += 1
    end
  end

  #-----------------------------------------------
  # Run Ruby
  #-----------------------------------------------

  def run_ruby(filename = 'out', keep = false)
    # Tape definition
    code = (@tape.instance_of?(Array) ? "tape = Array.new(#{@tape.size},0)" : 'tape = Hash.new(0)')
    code << "\npointer = 0"
    indent = ''
    # Match bytecode
    optimize_bytecode(make_bytecode(@program)).each {|c,arg,offset,set_multiplier|
      case c
      when INCREMENT # Tape
        code << "\n#{indent}tape[pointer#{"+#{offset}" if offset}] #{'+' unless set_multiplier}= #{arg}"
      when FORWARD # Pointer
        code << "\n#{indent}pointer += #{arg}"
      when WRITE # Write
        c = "putc(tape[pointer#{"+#{offset}" if offset}])"
        code << "\n#{indent}#{arg > 1 ? "#{arg}.times {#{c}}" : c}"
      when READ # Read
        c = "tape[pointer#{"+#{offset}" if offset}] = STDIN.getbyte"
        code << "\n#{indent}#{arg > 1 ? "#{arg}.times {#{c}}" : c}"
      when JUMP # Jump if zero
        code << "\n#{indent}until tape[pointer].zero?"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(0,2)
        code << "\n#{indent}end"
      when MULTIPLY # Multiplication
        code << "\n#{indent}tape[pointer+#{offset ? arg + offset : arg}] += tape[pointer#{"+#{offset}" if offset}]#{" * #{set_multiplier}" unless set_multiplier.zero?}"
      else raise "Unknown bytecode: #{c}"
      end
    }
    File.open("#{filename}.rb",'w') {|file| file << code} if keep
    eval(code)
    code
  end

  #-----------------------------------------------
  # Run C
  #-----------------------------------------------

  def run_c(filename, keep = false, flags = '-O2')
    if @tape.instance_of?(Array)
      tape_size = @tape.size
    else
      tape_size = TAPE_DEFAULT_SIZE
      puts "C mode requires a bounded tape, using #{tape_size} cells" if @debug
    end
    # Header
    code = "#include <stdio.h>\nint main(){\n  unsigned int tape[#{tape_size}] = {0};\n  unsigned int *pointer = tape;"
    indent = '  '
    # Match bytecode
    optimize_bytecode(make_bytecode(@program)).each {|c,arg,offset,set_multiplier|
      case c
      when INCREMENT # Tape
        code << "\n#{indent}*(pointer#{"+#{offset}" if offset}) #{'+' unless set_multiplier}= #{arg};"
      when FORWARD # Pointer
        code << "\n#{indent}pointer += #{arg};"
      when WRITE # Write
        c = "putchar(*(pointer#{"+#{offset}" if offset}));"
        code << "\n#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i; --i) #{c}" : c}"
      when READ # Read
        c = "(*(pointer#{"+#{offset}" if offset})) = getchar();"
        code << "\n#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i; --i) #{c}" : c}"
      when JUMP # Jump if zero
        code << "\n#{indent}while(*pointer){"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(0,2)
        code << "\n#{indent}}"
      when MULTIPLY # Multiplication
        code << "\n#{indent}*(pointer+#{offset ? arg + offset : arg}) += *(pointer#{"+#{offset}" if offset})#{" * #{set_multiplier}" unless set_multiplier.zero?};"
      else raise "Unknown bytecode: #{c}"
      end
    }
    code << "\n  return 0;\n}"
    file_c = "#{filename}.c"
    file_exe = "#{filename}.exe"
    File.open(file_c,'w') {|file| file << code}
    puts 'Compiling' if @debug
    system("gcc #{file_c} -o #{file_exe} #{flags}")
    puts 'Done' if @debug
    system(file_exe)
    File.delete(file_c, file_exe) unless keep
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
        if (bytecode.last[1] += -1).zero?
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
    # Clear and set [-] [+] [-]+ [+]-
    i = 0
    while i < bytecode.size
      if bytecode[i].first == JUMP and bytecode[i.succ].first == INCREMENT and bytecode[i+2].first == JUMPBACK
        # Clear
        bytecode[i] = [INCREMENT, 0, nil, true]
        # Set
        if bytecode[i+3].first == INCREMENT
          bytecode[i][1] = bytecode[i+3][1]
          bytecode.slice!(i.succ,3)
        else bytecode.slice!(i.succ,2)
        end
      end
      i += 1
    end
    # Multiplication [->+<]
    i = 0
    while i < bytecode.size
      if bytecode[i].first == JUMP
        j = i.succ
        while j < bytecode.size
          if bytecode[j].first == JUMP
            i = j
          elsif bytecode[j].first == JUMPBACK
            memory = Hash.new(0)
            pointer = 0
            i.succ.upto(j.pred) {|k|
              case bytecode[k].first
              when INCREMENT
                if bytecode[k][3]
                  pointer = nil
                  break
                end
                memory[pointer] = memory[pointer] + bytecode[k][1]
              when FORWARD
                pointer += bytecode[k][1]
              else
                pointer = nil
                break
              end
            }
            if pointer and pointer.zero? and memory[0] == -1
              memory.delete(0)
              bytecode[i..j] = memory.map {|key,value| [MULTIPLY, key, nil, value]} << [INCREMENT, 0, nil, true]
              stable = false
            else break
            end
          end
          j += 1
        end
      end
      i += 1
    end
    # Offset >+< <.>
    i = 0
    while i < bytecode.size.pred
      next_inst = bytecode[i.succ]
      if bytecode[i].first == FORWARD and (next_inst.first == INCREMENT or next_inst.first == WRITE or next_inst.first == READ or next_inst.first == MULTIPLY)
        # Push offset to next forward
        if bytecode[i+2] and bytecode[i+2].first == FORWARD
          bytecode.delete_at(i+2) if (bytecode[i+2][1] += bytecode[i][1]).zero?
          bytecode[i] = [next_inst.first, next_inst[1], bytecode[i][1], next_inst[3]]
          bytecode.delete_at(i.succ)
        # Swap forward with instruction
        else
          offset = bytecode[i]
          bytecode[i] = [next_inst.first, next_inst[1], bytecode[i][1], next_inst[3]]
          bytecode[i.succ] = offset
        end
      end
      i += 1
    end
    # Remove last forwards
    bytecode.pop while bytecode.last.first == FORWARD
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
      filename = ARGV[0] || File.expand_path('../mandelbrot.bf', __FILE__)
      mode = ARGV[1] || 'interpreter'
      # Bounded or infinity tape
      bounds = ARGV[2] ? ARGV[2].to_i : MindFreak::TAPE_DEFAULT_SIZE
      # Setup with clean tape
      MindFreak.debug = true
      MindFreak.setup(IO.read(filename), bounds > 0 ? Array.new(bounds, 0) : Hash.new(0))
      # Execute
      case mode
      when 'interpreter'
        puts 'Interpreter Mode'
        t = Time.now.to_f
        MindFreak.run_interpreter
        puts "\nTime: #{Time.now.to_f - t}s",'Tape:', MindFreak.tape.inspect
      when 'bytecode'
        puts 'Bytecode Mode'
        t = Time.now.to_f
        MindFreak.run_bytecode
        puts "\nTime: #{Time.now.to_f - t}s",'Tape:', MindFreak.tape.inspect
      when 'rb'
        puts 'Ruby Mode'
        t = Time.now.to_f
        MindFreak.run_ruby(filename, true)
        puts "\nTime: #{Time.now.to_f - t}s"
      when 'c'
        puts 'C Mode'
        t = Time.now.to_f
        MindFreak.run_c(filename, true)
        puts "\nTime: #{Time.now.to_f - t}s"
      else raise 'Mode not found'
      end
    end
  rescue Interrupt
    puts "\nTape: #{MindFreak.tape.inspect}", "Pointer: #{MindFreak.pointer}" if mode == 'interpreter' or mode == 'bytecode'
  rescue
    puts $!, $@
    STDIN.gets
  end
end