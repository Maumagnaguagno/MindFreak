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

  MULTIPLY  = '*'.ord

  attr_reader :program, :bytecode, :rubycode, :tape, :pointer

  #-----------------------------------------------
  # Initialize
  #-----------------------------------------------

  def initialize(program, bounded_tape = nil)
    # Program cleaned
    @program = program
    @program.gsub!(/[^+-><.,\[\]]/,'')
    # Bounded
    if bounded_tape.is_a?(Fixnum) and bounded_tape > 0
      @tape = Array.new(bounded_tape, 0)
      @bounded_tape = bounded_tape
    # Infinity tape
    else
      @tape = Hash.new(0)
    end
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
    if @bounded_tape
      @tape.fill(0)
    else
      @tape.clear
    end
    @program_counter = @pointer = @control = 0
    # Intepreter
    until @program_counter == @program.size
      case @program[@program_counter]
      when '+' # Increment
        @tape[@pointer] += 1
      when '-' # Decrement
        @tape[@pointer] -= 1
      when '>' # Forward
        @pointer += 1
      when '<' # Backward
        @pointer -= 1
      when '.' # Write
        putc(@tape[@pointer])
      when ',' # Read
        @tape[@pointer] = gets[0].ord
      when '[' # Jump if zero
        if @tape[@pointer].zero?
          @control = 1
          until @control.zero?
            @program_counter += 1
            case @program[@program_counter]
            when '['
              @control += 1
            when ']'
              @control -= 1
            end
          end
        end
      when ']' # Return unless zero
        unless @tape[@pointer].zero?
          @control = -1
          until @control.zero?
            @program_counter -= 1
            case @program[@program_counter]
            when '['
              @control += 1
            when ']'
              @control -= 1
            end
          end
        end
      end
      @program_counter += 1
    end
  end

  #-----------------------------------------------
  # Make bytecode
  #-----------------------------------------------

  def make_bytecode
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
  end

  #-----------------------------------------------
  # Optimization
  #-----------------------------------------------

  def optimization(level = 3)
    puts "Bytecode original size: #{@bytecode.size}"
    loop {
      stable = true
      i = 0
      while i < @bytecode.size
        # Set cell [-]+
        if @bytecode[i].first == JUMP and @bytecode[i+1] == [INCREMENT,-1] and @bytecode[i+2].first == JUMPBACK
          # Clear
          @bytecode[i] = [INCREMENT,0,nil,true]
          # Set
          if @bytecode[i+3].first == INCREMENT
            @bytecode[i][1] += @bytecode[i+3][1]
            @bytecode.slice!(i+1,3)
          else
            @bytecode.slice!(i+1,2)
          end
          stable = false
        # Loop multiplication
=begin
        elsif @bytecode[i].first == JUMP and @bytecode[i+1] == [INCREMENT,-1]
          j = i+2
          j += 1 while @bytecode[j].first == INCREMENT
          j -= 1
          if @bytecode[j].first == JUMPBACK
            puts 'MULTIPLY'
            @bytecode.slice!(i,2)
            @bytecode.slice!(j)
            (i+2).upto(j) {|k| @bytecode[k] = [MULTIPLY,0]}
          end
=end
        # Pointer movement >+< <.>
        elsif @bytecode[i].first == BACKWARD and (@bytecode[i+1].first == INCREMENT or @bytecode[i+1].first == WRITE) and @bytecode[i+2].first == BACKWARD
          # Jump value
          @bytecode[i+2][1] += @bytecode[i][1]
          @bytecode.slice!(i+2) if @bytecode[i+2][1].zero?
          # Add pointer
          @bytecode[i] = [@bytecode[i+1][0], @bytecode[i+1][1], @bytecode[i][1], @bytecode[i+1][3]]
          @bytecode.slice!(i+1)
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
    make_bytecode
    if @bounded_tape
      @tape.fill(0)
    else
      @tape.clear
    end
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
      end
      @program_counter += 1
    end
  end

  #-----------------------------------------------
  # Run Ruby
  #-----------------------------------------------

  def run_ruby(output = nil, optimize = true)
    make_bytecode
    # Optimizations
    optimization if optimize
    # Tape definition
    @rubycode = @bounded_tape ? "tape = Array.new(#{@bounded_tape},0)" : "tape = Hash.new(0)"
    @rubycode << "\npointer = 0"
    # Pretty print
    ident = '  '
    level = 0
    # Match each bytecode
    @bytecode.each {|c,arg,offset,set|
      case c
      when INCREMENT # Tape
        @rubycode << "\n#{ident * level}tape[pointer#{offset ? "+#{offset}]" : ']'} #{set ? '=' : '+='} #{arg}"
      when BACKWARD # Pointer
        @rubycode << "\n#{ident * level}pointer += #{arg}"
      when WRITE # Write
        c = "putc(tape[pointer" << (offset ? "+#{offset}])" : '])')
        @rubycode << "\n#{ident * level}#{arg > 1 ? "#{arg}.times {#{c}}" : c}"
      when READ # Read
        @rubycode << "\n#{ident * level}#{arg > 1 ? "#{arg}.times {tape[pointer] = gets[0].ord}" : 'tape[pointer] = gets[0].ord'}"
      when JUMP # Jump if zero
        @rubycode << "\n#{ident * level}until tape[pointer].zero?"
        level += 1
      when JUMPBACK # Return unless zero
        level -= 1
        @rubycode << "\n#{ident * level}end"
      end
    }
    File.open(output,'w') {|file| file << @rubycode} if output
    eval(@rubycode)
  end
end

#-----------------------------------------------
# Main
#-----------------------------------------------
begin
  # Mode
  INTERPRETER = false
  BYTECODE = false
  RUBY = true
  RUBY_OUTPUT = 'output.rb'
  BOUNDS = 500
  # Setup
  mind = MindFreak.new(IO.read(ARGV[0] || 'mandelbrot.bfk'), BOUNDS)
  # Check Syntax
  if mind.check
      # Interpreter
    if INTERPRETER
      puts 'Interpreter Mode',''
      t = Time.now.to_f
      mind.run_interpreter
      puts "\nTime: #{Time.now.to_f - t}s"
      puts "\nTape:", mind.tape.inspect
      puts '-' * 100
    end
    # Bytecode
    if BYTECODE
      puts 'Bytecode Mode',''
      t = Time.now.to_f
      mind.run_bytecode
      puts "\nTime: #{Time.now.to_f - t}s"
      puts "\nTape:", mind.tape.inspect
      puts '-' * 100
    end
    # Ruby
    if RUBY
      puts 'Ruby Mode',''
      t = Time.now.to_f
      mind.run_ruby(RUBY_OUTPUT)
      puts "\nTime: #{Time.now.to_f - t}s"
    end
  # Ops
  else
    puts 'Unbalanced brackets... tsc tsc...'
  end
rescue Interrupt
  puts "\nTape: #{mind.tape}", "Pointer: #{mind.pointer}" unless RUBY
rescue
  puts $!, $@
  STDIN.gets
end
