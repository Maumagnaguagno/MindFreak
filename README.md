# MindFreak
A BrainFuck interpreter with bytecode support and language converter

Started this project during October 2013 to see something easy to parse for a change. The goals was to understand how much could be optimized from the source. Ended up discovering a lot of crazy ideas about bytecode and macro optimizations. Really fun to do in a weekend, would take a lifetime to master though. Most of my work was inspired by [Nayuki] and the awesome implementation of a Mandelbrot fractal by Erik Bosman.

### What is this?
BrainFuck is a simple language with almost the minimal set of instructions somebody needs to do anything. The idea is that you are in control of a Turing machine without abstractions, like variables and function libraries, only being able to move the pointer/head and writing to the current cell in the tape. You only have access to this set of instructions:
- **>** 	move pointer to the right ```pointer += 1```
- **<** 	move pointer to the left ```pointer -= 1```
- **+** 	increment value of cell ```tape[pointer] += 1```
- **-** 	decrement value of cell ```tape[pointer] -= 1```
- **.** 	output the value of cell, usually this byte is mapped to a character ```output(tape[pointer])```
- **,** 	input the value of cell, usually a char is converted to a byte ```tape[pointer] = input```
- **[** 	if the cell at the pointer is zero, jumps the block ```while tape[pointer] != 0```
- **]** 	if the cell at the pointer is nonzero, then jump back to the beginning of block ```end of while```

### Examples
This makes even simple things like setting a variable to a zero a problem:
```
[-]
```

### Compatibility
And different implementations of the limits make it even more complex(bold is the ones supported by this project):
- Size of cell (bit, char, **unbounded**)
- Size of tape (**pre-allocated**, **allocated as required**)
- How the input happens (file or **terminal**)
- How the output happens (file or **terminal**)

### Support
- Unbounded cell value
- Bounded ou unbounded tape
- Interpret +-><.,[] as commands, the rest as comments
- Check brackets before execution
- Output tape when interrupted
- Bytecode mode (faster than executing what the user provided)
- Ruby Mode (transform bytecode to ruby to get even more speed)

### ToDo's
- Debug System, verbose, step-by-step, breakpoint
- Interactive mode
- Use input tape or keyboard to deal with inputs
- Tests

[Nayuki]:http://www.nayuki.io/page/optimizing-brainfuck-compiler
