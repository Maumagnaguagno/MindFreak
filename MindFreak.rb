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

  # TODO MULTIPLY  = ?*.ord
  

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
        @tape[@pointer] = @input.getc.ord
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
        arg.times {@tape[@pointer] = @input.getc.ord}
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

  def run_ruby(filename, keep = false)
    # Tape definition
    rubycode = @tape.instance_of?(Array) ? "tape = Array.new(#{@tape.size},0)" : 'tape = Hash.new(0)'
    rubycode << "\npointer = 0"
    indent = ''
    # Match bytecode
    optimize_bytecode(make_bytecode(@program)).each {|c,arg,offset,set|
      case c
      when INCREMENT # Tape
        rubycode << "\n#{indent}tape[pointer#{"+#{offset}" if offset}] #{'+' unless set}= #{arg}"
      when FORWARD # Pointer
        rubycode << "\n#{indent}pointer += #{arg}"
      when WRITE # Write
        c = "putc(tape[pointer#{"+#{offset}" if offset}])"
        rubycode << "\n#{indent}#{arg > 1 ? "#{arg}.times {#{c}}" : c}"
      when READ # Read
        c = "tape[pointer#{"+#{offset}" if offset}] = STDIN.getc.ord"
        rubycode << "\n#{indent}#{arg > 1 ? "#{arg}.times {#{c}}" : c}"
      when JUMP # Jump if zero
        rubycode << "\n#{indent}until tape[pointer].zero?"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(0,2)
        rubycode << "\n#{indent}end"
      else raise "Unknown bytecode: #{c}"
      end
    }
    File.open("#{filename}.rb",'w') {|file| file << rubycode} if keep
    eval(rubycode)
    rubycode
  end

  #-----------------------------------------------
  # Run C
  #-----------------------------------------------

  def run_c(filename, flags = '-O2', keep = false)
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
    optimize_bytecode(make_bytecode(@program)).each {|c,arg,offset,set|
      case c
      when INCREMENT # Tape
        code << "\n#{indent}*(pointer#{"+#{offset}" if offset}) #{'+' unless set}= #{arg};"
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
      else raise "Unknown bytecode: #{c}"
      end
    }
    code << "\n  return 0;\n}"
    file_c = "#{filename}.c"
    file_exe = "#{filename}.exe"
    File.open(file_c,'w') {|file| file << code}
    system("gcc #{file_c} -o #{file_exe} #{flags}")
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

  def optimize_bytecode(bytecode, level = 3)
    loop {
      stable = true
      i = 0
      while i < bytecode.size
        # Set cell [-]+
        if bytecode[i].first == JUMP and bytecode[i.succ] == [INCREMENT,-1] and bytecode[i+2].first == JUMPBACK
          # Clear
          bytecode[i] = [INCREMENT, 0, nil, true]
          # Set
          if bytecode[i+3].first == INCREMENT
            bytecode[i][1] += bytecode[i+3][1]
            bytecode.slice!(i.succ,3)
          else
            bytecode.slice!(i.succ,2)
          end
          stable = false
=begin
        # Loop multiplication
        elsif bytecode[i].first == JUMP and bytecode[i.succ] == [INCREMENT,-1]
          j = i + 2
          j += 1 while bytecode[j].first == INCREMENT
          if bytecode[j].first == JUMPBACK
            j -= 1
            puts 'MULTIPLY'
            bytecode.slice!(i,2)
            bytecode.delete_at(j)
            (i+2).upto(j) {|k| bytecode[k] = [MULTIPLY,0]}
          end
          stable = false
=end
        # Pointer movement >+< <.>
        elsif bytecode[i].first == FORWARD and (bytecode[i.succ].first == INCREMENT or bytecode[i.succ].first == WRITE) and bytecode[i+2].first == FORWARD
          # Jump value
          bytecode.delete_at(i+2) if (bytecode[i+2][1] += bytecode[i][1]).zero?
          # Add pointer
          bytecode[i] = [bytecode[i.succ][0], bytecode[i.succ][1], bytecode[i][1], bytecode[i.succ][3]]
          bytecode.delete_at(i.succ)
          stable = false
        end
        i += 1
      end
      level -= 1
      return bytecode if stable or level.zero?
      puts "Bytecode optimized to size: #{bytecode.size}" if @debug
    }
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    # Help
    if ARGV.first == '-h'
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
        MindFreak.run_ruby(filename)
        puts "\nTime: #{Time.now.to_f - t}s"
      when 'c'
        puts 'C Mode'
        t = Time.now.to_f
        MindFreak.run_c(filename)
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