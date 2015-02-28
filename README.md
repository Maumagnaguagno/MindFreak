# MindFreak
A BrainFuck interpreter with bytecode support and language converter

Started this project during October 2013 to see something easy to parse for a change. The goal was to understand how much could be optimized from the source. Ended up discovering a lot of crazy ideas about bytecode and macro optimizations. Really fun to do in a weekend, but do not let the funny name fool you, would take a lifetime to master. Most of my work was inspired by [Nayuki] and the awesome implementation of a Mandelbrot fractal generator by Erik Bosman.

### What is this language?
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
BrainFuck can get tricky, we need to optimize in order to generate code that finishes execution in our lifetime.
The lack of common operators makes even simple things, like setting a variable to a zero, a loop:  
- ```[-]```
  - ```while(tape[pointer] != 0) tape[pointer] -= 1```
    - ```tape[pointer] = 0```  

Setting a variable requires the cell to be cleared and updated:
- ```[-]++```
  - ```while(tape[pointer] != 0) tape[pointer] -= 1; tape[pointer] += 2```
    - ```tape[pointer] = 2```

Pointer movement can be a pain, checking a cell nearby and returning to its initial state costs cycles. We want those cycles back:
- ```>+<```
  - ```pointer += 1; tape[pointer] += 1; pointer -= 1```
    - ```tape[pointer+1] += 1```

But there is much more to be optimized, sometimes variations and two optimizations at the same time are hard to apply. The solution was to run multiple times the optimizer. I am currently working on the while N case for a cell that is decremented by 1 by each iteration:
```
while(tape[pointer] != 0)
{
  tape[pointer] -= 1;
  ...
}
```
The optimized version would be:
```
counter = tape[pointer]
while(counter != 0)
{
  counter -= 1
  
}
tape[pointer] = 0
```

[Nayuki] has even more optimizations! Which is awesome and sad at the same time, maybe I will never have time to implement them all.

### Compatibility
Compatibility should not be a problem for a limited instruction set, but different implementations of the limits make it complex (in bold the ones supported by this project):
- Size of cell (bit, byte, word, other fixed size, **unbounded**)
- Size of tape (**pre-allocated**, **allocated as required**)
- How the input happens (file, **read from terminal**)
- How the output happens (file, **write to terminal**)
- Unknown instructions (**ignore**, halt, extended instructions)

### Support
- Unbounded cell value
- Bounded (fast Array) ou unbounded tape (slow Hash)
- Interpret +-><.,[] as commands, the rest as comments
- Check brackets before execution
- Output tape when interrupted (for interpreted modes, not for Ruby's eval)
- Bytecode mode (faster than executing what the user provided)
- Ruby Mode (transform bytecode to ruby and eval to get even more speed)

### ToDo's
- Debug System, verbose, step-by-step, breakpoint
- Interactive mode
- Optional input tape to deal with inputs (faster testing)
- Tests

[Nayuki]:http://www.nayuki.io/page/optimizing-brainfuck-compiler
