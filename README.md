# MindFreak [![Build Status](https://travis-ci.org/Maumagnaguagno/MindFreak.svg)](https://travis-ci.org/Maumagnaguagno/MindFreak)
A BrainFuck interpreter with bytecode and language conversion

Started this project during October 2013 to see something easy to parse for a change.
The goal was to understand how much could be optimized from the source.
Ended up discovering a lot of crazy ideas about bytecode and macro optimizations.
Really fun to do in a weekend, but do not let the funny name fool you, would take a lifetime to master.
Most of my work was inspired by [Nayuki](http://www.nayuki.io/page/optimizing-brainfuck-compiler) and the awesome implementation of a Mandelbrot fractal generator by Erik Bosman.

### What is BrainFuck?
BrainFuck is a simple language with almost the minimal set of instructions someone needs to do anything.
The idea is that you are in control of a Turing machine without abstractions, like variables and function libraries, only being able to move the pointer/head and writing to the current cell in the tape.
You only have access to this set of instructions:
- **>** move pointer to the right ```pointer += 1```
- **<** move pointer to the left ```pointer -= 1```
- **+** increment value of cell ```tape[pointer] += 1```
- **-** decrement value of cell ```tape[pointer] -= 1```
- **.** output the value of cell, usually this byte is mapped to a character ```output(tape[pointer])```
- **,** input the value of cell, usually a char is converted to a byte ```tape[pointer] = input```
- **[** if the cell at the pointer is zero, jumps the block ```while tape[pointer] != 0```
- **]** if the cell at the pointer is nonzero, then jump back to the beginning of block ```end of while```

### Examples
BrainFuck can get tricky, we need to optimize in order to generate code that finishes execution in our lifetime.
The lack of common operators makes even simple things, like setting a variable to a zero, a loop:  
```
Original:  [-]
Converted: while(tape[pointer] != 0) tape[pointer] -= 1;
Optimized: tape[pointer] = 0;
```

Setting a variable requires the cell to be cleared and updated:
```
Original:  [-]++
Converted: while(tape[pointer] != 0) tape[pointer] -= 1; tape[pointer] += 2;
Optimized: tape[pointer] = 2;
```

Pointer movement can be a pain, checking a cell nearby and returning to its initial state costs cycles. We want those cycles back:
```
Original:  >+<
Converted: pointer += 1; tape[pointer] += 1; pointer -= 1;
Optimized: tape[pointer+1] += 1;
```

But there is [much more to be optimized](http://calmerthanyouare.org/2015/01/07/optimizing-brainfuck.html), sometimes variations and two optimizations at the same time are hard to apply.
The solution is to apply optimizations following a certain order.
This project contracts several operations at the first level of bytecode generation and them apply the hard optimizations, generating a more complex bytecode.

[Nayuki](http://www.nayuki.io/page/optimizing-brainfuck-compiler) has even more optimizations!
Which is awesome and sad at the same time, maybe I will never have time to implement them all.
Since I can output C code we can expect GCC to solve this problem for us.

### Compatibility
Compatibility should not be a problem for a limited instruction set, but different implementations of the limits make it complex to support.
In bold what is supported by this project:
- Size of cell (bit, **byte/unsigned char**, **word/unsigned int**, **other C fixed size**, **unbounded**)
- Size of tape (**pre-allocated**, **allocated as required**)
- How the input happens (**IO object**, **read from terminal**)
- How the output happens (**IO object**, **write to terminal**)
- Unknown instructions (**ignore**, halt, extended instructions)

### Support
- Bounded (fast Array) ou unbounded tape (slow Hash)
- Ignore comments and check brackets before execution
- Interpreter mode, apply instructions as user provided
- Bytecode mode (cluster repeated instructions to achieve speed-up)
- Bytecode2 mode (uses optimized bytecode to achieve even more speed-up)
- Ruby Mode (transform optimized bytecode to ruby and eval to get even more speed)
- The C mode works like the Ruby one, but cells are limited to fixed size and bounded tape
- Output tape when interrupted (for interpreted and bytecode modes, not for Ruby or C)

### Execution
```
ruby MindFreak.rb filename.bf [interpreter|bytecode|bytecode2|rb|c] [bounds]
```

The current implementation expects the brainfuck filename, execution mode and tape bounds.
The C mode is the fastest, it requires GCC in your path so you can compile and have an executable.
The tape is bounded by default to 500 cells, make it 0 to support any size.
An unbounded tape is slower and C mode will use the default size to allocate the tape.
The main of this project is just an example of the API, you can run all modes in sequence if you like.

### API
The entire MindFreak is contained in a module with the same name.
It has 4 attributes:
- ```attr_reader :pointer```, with the position of the current cell for interpreted execution modes, starts with ```nil```.
- ```attr_accessor :input```, read external data from an object that responds to ```getbyte```, starts with ```STDIN```.
- ```attr_accessor :output```, write external data to an object that responds to ```putc``` and ```print```, starts with ```STDOUT```.
- ```attr_accessor :debug```,  print warnings when set to anything but ```false``` or ```nil```, starts with ```nil```.

The methods require a String containing the program and an Array or Hash to be used as tape.
The bytecode generated is an Array or Arrays and differ from the basic to the optimized version.
- ```check_program(program)``` is used to sanitize the input program and check if brackets are balanced, modifies the program string, returns nil.
- ```run_interpreter(program, tape)``` executes the slow interpreter, reading from input, writing to output while using the provided tape.
- ```run_bytecode(program, tape)``` executes the bytecode interpreter, reading from input, writing to output while using the provided tape.
- ```run_bytecode2(program, tape)``` executes the optimized bytecode interpreter, reading from input, writing to output while using the provided tape.
- ```to_ruby(program, tape = nil, input = 'STDIN', output = 'STDOUT')``` returns a string with a Ruby equivalent to the program provided. If no tape is provided the string will not contain a tape and pointer declaration, this forces ```eval``` to use external variables.
- ```to_c(program, tape, type = 'unsigned int')``` returns a string with a C equivalent to the program provided. The type contains the cell type being used.
- ```make_bytecode(program)``` returns an Array with the bytecodes.
- ```optimize_bytecode(bytecode)``` returns an Array with the optimized bytecodes.

The basic bytecode is described by the tuple ```[instruction, argument]```, in which:
- **instruction** corresponds to the byte value of each instruction char used in BrainFuck;
- **argument** corresponds to the amount of times this instruction is used or the index to jump in case of ```[``` or ```]```.

The extended bytecode adds a multiply instruction, defined by ```*``` and more information to each bytecode,
It is described by the tuple ```[instruction, argument, offset, set or multiplier]```, in which:
- **offset** is added to the current pointer;
- **set** can be used to set a cell to a value when used by ```+``` or multiplied by a factor when used by ```*```.
The test file contains several examples about the usage of the bytecode and can be used as a guide.

### ToDo's
- Generate C code with non-blank tape
- Step-by-step/interactive mode, breakpoint
- Add examples