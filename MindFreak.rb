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
#-----------------------------------------------
# TODO
# - Debug System, verbose, step-by-step, breakpoint
# - Interactive mode
# - Use input tape or keyboard
#-----------------------------------------------

class MindFreak

  INCREMENT = ?+.ord
  DECREMENT = ?-.ord
  FORWARD   = ?>.ord
  BACKWARD  = ?<.ord
  WRITE     = ?..ord
  READ      = ?,.ord
  JUMP      = ?[.ord
  JUMPBACK  = ?].ord

  MULTIPLY  = ?*.ord

  attr_reader :program, :bytecode, :tape, :pointer

  #-----------------------------------------------
  # Initialize
  #-----------------------------------------------

  def initialize(program, bounded_tape = nil)
    # Program cleaned
    @program = program
    @program.gsub!(/[^+-><.,\[\]]/,'')
    # Bounded or infinity tape
    @tape = bounded_tape > 0 ? Array.new(bounded_tape, 0) : Hash.new(0)
  end

  #-----------------------------------------------
  # Check
  #-----------------------------------------------

  def check
    # Check balanced brackets
    control = 0
    @program.each_byte {|c|
      case c
      when JUMP
        control += 1
      when JUMPBACK
        return false if (control -= 1) < 0
      end
    }
    control.zero?
  end

  #-----------------------------------------------
  # Run interpreter
  #-----------------------------------------------

  def run_interpreter
    @tape.instance_of?(Array) ? @tape.fill(0) : @tape.clear
    @program_counter = @pointer = @control = 0
    # Intepreter
    until @program_counter == @program.size
      case @program[@program_counter]
      when ?+ # Increment
        @tape[@pointer] += 1
      when ?- # Decrement
        @tape[@pointer] -= 1
      when ?> # Forward
        @pointer += 1
      when ?< # Backward
        @pointer -= 1
      when ?. # Write
        putc(@tape[@pointer])
      when ?, # Read
        @tape[@pointer] = gets[0].ord
      when ?[ # Jump if zero
        if @tape[@pointer].zero?
          @control = 1
          until @control.zero?
            @program_counter += 1
            case @program[@program_counter]
            when ?[
              @control += 1
            when ?]
              @control -= 1
            end
          end
        end
      when ?] # Return unless zero
        unless @tape[@pointer].zero?
          @control = -1
          until @control.zero?
            @program_counter -= 1
            case @program[@program_counter]
            when ?[
              @control += 1
            when ?]
              @control -= 1
            end
          end
        end
      else raise "Unknown instruction: #{@program[@program_counter]}"
      end
      @program_counter += 1
    end
  end

  #-----------------------------------------------
  # Make bytecode
  #-----------------------------------------------

  def make_bytecode(optimize)
    @bytecode = []
    jump_stack = []
    # Compress
    last = pc = index = 0
    @program.each_byte {|c|
      if c == last
        if c == DECREMENT or c == BACKWARD
          @bytecode.last[1] -= 1
        else
          @bytecode.last[1] += 1
        end
      else
        # Not Jump
        if c < JUMP
          last = c
          @bytecode << [c == DECREMENT ? INCREMENT : c == FORWARD ? BACKWARD : c, (c == DECREMENT || c == BACKWARD) ? -1 : 1]
        # Jump
        else
          last = 0
          if c == JUMP
            @bytecode << [c]
            jump_stack << index
          else
            # Jump program counter to index, only works for bytecode
            @bytecode << [c,jump_stack.last]
            @bytecode[jump_stack.pop] << index
          end
        end
        index += 1
      end
    }
    puts "Bytecode size: #{@bytecode.size}"
    optimization if optimize
  end

  #-----------------------------------------------
  # Optimization
  #-----------------------------------------------

  def optimization(level = 3)
    loop {
      stable = true
      i = 0
      while i < @bytecode.size
        # Set cell [-]+
        if @bytecode[i].first == JUMP and @bytecode[i.succ] == [INCREMENT,-1] and @bytecode[i+2].first == JUMPBACK
          # Clear
          @bytecode[i] = [INCREMENT,0,nil,true]
          # Set
          if @bytecode[i+3].first == INCREMENT
            @bytecode[i][1] += @bytecode[i+3][1]
            @bytecode.slice!(i.succ,3)
          else
            @bytecode.slice!(i.succ,2)
          end
          stable = false
=begin
        # Loop multiplication
        elsif @bytecode[i].first == JUMP and @bytecode[i.succ] == [INCREMENT,-1]
          j = i + 2
          j += 1 while @bytecode[j].first == INCREMENT
          if @bytecode[j].first == JUMPBACK
            j -= 1
            puts 'MULTIPLY'
            @bytecode.slice!(i,2)
            @bytecode.slice!(j)
            (i+2).upto(j) {|k| @bytecode[k] = [MULTIPLY,0]}
          end
          stable = false
=end
        # Pointer movement >+< <.>
        elsif @bytecode[i].first == BACKWARD and (@bytecode[i.succ].first == INCREMENT or @bytecode[i.succ].first == WRITE) and @bytecode[i+2].first == BACKWARD
          # Jump value
          @bytecode[i+2][1] += @bytecode[i][1]
          @bytecode.slice!(i+2) if @bytecode[i+2][1].zero?
          # Add pointer
          @bytecode[i] = [@bytecode[i.succ][0], @bytecode[i.succ][1], @bytecode[i][1], @bytecode[i.succ][3]]
          @bytecode.slice!(i.succ)
          stable = false
        end
        i += 1
      end
      level -= 1
      return if stable or level.zero?
      puts "Bytecode optimized size: #{@bytecode.size}"
    }
  end

  #-----------------------------------------------
  # Run bytecode
  #-----------------------------------------------

  def run_bytecode
    # Bytecode interpreter does not support optimizations
    make_bytecode(false)
    @tape.instance_of?(Array) ? @tape.fill(0) : @tape.clear
    @program_counter = @pointer = @control = 0
    # Execute
    until @program_counter == @bytecode.size
      c, arg = @bytecode[@program_counter]
      case c
      when INCREMENT # Tape
        @tape[@pointer] += arg
      when BACKWARD # Pointer
        @pointer += arg
      when WRITE # Write
        arg.times {putc(@tape[@pointer])}
      when READ # Read
        arg.times {@tape[@pointer] = gets[0].ord}
      when JUMP # Jump if zero
        @program_counter = arg if @tape[@pointer].zero?
      when JUMPBACK # Return unless zero
        @program_counter = arg unless @tape[@pointer].zero?
      else raise "Unknown bytecode: #{c}"
      end
      @program_counter += 1
    end
  end

  #-----------------------------------------------
  # Run Ruby
  #-----------------------------------------------

  def run_ruby(filename, keep = false)
    make_bytecode(true)
    # Tape definition
    rubycode = @tape.instance_of?(Array) ? "tape = Array.new(#{@tape.size},0)" : "tape = Hash.new(0)"
    rubycode << "\npointer = 0"
    indent = ''
    # Match bytecode
    @bytecode.each {|c,arg,offset,set|
      case c
      when INCREMENT # Tape
        rubycode << "\n#{indent}tape[pointer#{"+#{offset}" if offset}] #{'+' unless set}= #{arg}"
      when BACKWARD # Pointer
        rubycode << "\n#{indent}pointer += #{arg}"
      when WRITE # Write
        c = "putc(tape[pointer#{"+#{offset}" if offset}])"
        rubycode << "\n#{indent}#{arg > 1 ? "#{arg}.times {#{c}}" : c}"
      when READ # Read
        c = "tape[pointer#{"+#{offset}" if offset}] = gets[0].ord"
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
    raise 'Tape must be bounded for C mode' unless @tape.instance_of?(Array)
    make_bytecode(true)
    # Header
    @code = "#include <stdio.h>\nint main(){\n  unsigned int tape[#{@tape.size}] = {0};\n  unsigned int *pointer = tape;"
    indent = '  '
    # Match bytecode
    @bytecode.each {|c,arg,offset,set|
      case c
      when INCREMENT # Tape
        @code << "\n#{indent}*(pointer#{"+#{offset}" if offset}) #{'+' unless set}= #{arg};"
      when BACKWARD # Pointer
        @code << "\n#{indent}pointer += #{arg};"
      when WRITE # Write
        c = "putchar(*(pointer#{"+#{offset}" if offset}));"
        @code << "\n#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i; --i) #{c}" : c}"
      when READ # Read
        c = "(*(pointer#{"+#{offset}" if offset})) = getchar();"
        @code << "\n#{indent}#{arg > 1 ? "for(unsigned int i = #{arg}; i; --i) #{c}" : c}"
      when JUMP # Jump if zero
        @code << "\n#{indent}while(*pointer){"
        indent << '  '
      when JUMPBACK # Return unless zero
        indent.slice!(0,2)
        @code << "\n#{indent}}"
      else raise "Unknown bytecode: #{c}"
      end
    }
    @code << "\n  return 0;\n}"
    file_c = "#{filename}.c"
    file_exe = "#{filename}.exe"
    File.open(file_c,'w') {|file| file << @code}
    system("gcc #{file_c} -o #{file_exe} #{flags}")
    t = Time.now.to_f
    system(file_exe)
    puts "\nTime: #{Time.now.to_f - t}s"
    File.delete(file_c, file_exe) unless keep
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
if $0 == __FILE__
  begin
    # Help
    if ARGV.first == '-h'
      puts "MindFreak [filename=mandelbrot.bf] [mode=interpreter|bytecode|rb|c] [bounds=500|<int>]"
    else
      # Input
      filename = ARGV[0] || File.expand_path('../mandelbrot.bf', __FILE__)
      mode = ARGV[1] || 'interpreter'
      bounds = ARGV[2] ? ARGV[2].to_i : 500
      # Setup
      mind = MindFreak.new(IO.read(filename), bounds)
      # Check Syntax
      if mind.check
        # Execute
        case mode
        when 'interpreter'
          puts 'Interpreter Mode',''
          t = Time.now.to_f
          mind.run_interpreter
          puts "\nTime: #{Time.now.to_f - t}s",'Tape:', mind.tape.inspect, '-' * 100
        when 'bytecode'
          puts 'Bytecode Mode',''
          t = Time.now.to_f
          mind.run_bytecode
          puts "\nTime: #{Time.now.to_f - t}s",'Tape:', mind.tape.inspect, '-' * 100
        when 'rb'
          puts 'Ruby Mode',''
          t = Time.now.to_f
          mind.run_ruby(filename)
          puts "\nTime: #{Time.now.to_f - t}s", '-' * 100
        when 'c'
          puts 'C Mode',''
          mind.run_c(filename)
        else raise 'Mode not found'
        end
      # Ops
      else puts 'Unbalanced brackets... tsc tsc...'
      end
    end
  rescue Interrupt
    puts "\nTape: #{mind.tape.inspect}", "Pointer: #{mind.pointer}" if mode == 'interpreter' or mode == 'bytecode'
  rescue
    puts $!, $@
    STDIN.gets
  end
end