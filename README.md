# MindFreak [![Actions Status](https://github.com/Maumagnaguagno/MindFreak/workflows/build/badge.svg)](https://github.com/Maumagnaguagno/MindFreak/actions)
**A BrainFuck interpreter with bytecode and language conversion**

Started this project during October 2013 to see something easy to parse for a change.
The goal was to understand how much could be optimized from the source.
Ended up discovering a lot of crazy ideas about bytecode and macro optimizations.
Really fun to do in a weekend, but do not let the funny name fool you, would take a lifetime to master.
Most of my work was inspired by [Nayuki] and the awesome implementation of a [Mandelbrot fractal generator](mandelbrot.bf) by Erik Bosman.

## What is BrainFuck?
BrainFuck is a simple language with almost the minimal set of instructions someone needs to do anything.
The idea is that you are in control of a Turing machine without abstractions, like variables and functions, only being able to move the pointer/head and writing to the current cell in the tape.
You only have access to these instructions:
- <kbd>></kbd> move pointer forward ``pointer += 1``
- <kbd><</kbd> move pointer backward ``pointer -= 1``
- <kbd>+</kbd> increment cell value ``tape[pointer] += 1``
- <kbd>-</kbd> decrement cell value ``tape[pointer] -= 1``
- <kbd>.</kbd> output cell value as character ``output(tape[pointer])``
- <kbd>,</kbd> input cell value as character byte ``tape[pointer] = input``
- <kbd>[</kbd> if cell value is zero, jump over block ``while tape[pointer] != 0``
- <kbd>]</kbd> if cell value is nonzero, jump to block beginning ``end of while``

## Examples
BrainFuck can get tricky, we need to optimize in order to generate code that finishes execution in our lifetime.
The lack of common operators makes even simple things, like assign a variable to a zero, a loop:

```
Original:  [-]
Converted: while(tape[pointer] != 0) tape[pointer] -= 1;
Optimized: tape[pointer] = 0;
```

Variable assignment requires the cell to be cleared and updated:

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
This project contracts several operations at the first level of bytecode generation and then apply the hard optimizations, generating a more complex bytecode.

[Nayuki] has even more optimizations!
Which is awesome and sad at the same time, maybe I will never have time to implement them all.
Since it can output C code we can expect GCC/Clang to solve this problem for us.

## Compatibility
Compatibility should not be a problem for a limited instruction set, but different implementations of the limits make it complex.
In bold what is supported by this project:
- Size of cell (bit, **byte/unsigned char**, **word/unsigned int**, **other C fixed size**, **unbounded**)
- Size of tape (**pre-allocated**, **allocated as required**)
- How the input happens (**IO object**, **read from terminal**)
- How the output happens (**IO object**, **write to terminal**)
- Unknown instructions (**ignore**, halt, extended instructions)
- EOF (**any integer**, **unchanged**)

### Support
- Bounded (fast Array) or unbounded (slow Hash) tape
- Ignore comments and check brackets before execution
- Interpreter mode, apply instructions as user provided
- Bytecode mode (cluster repeated instructions to achieve speed-up)
- Bytecode2 mode (uses optimized bytecode to achieve even more speed-up)
- Ruby mode (transform optimized bytecode to ruby and eval to get even more speed)
- C mode works like Ruby mode with fixed size tape and cells
- Custom EOF, ``0`` is the default (C is faster with ``-1``), ``unchanged``
- Output tape when interrupted (except C mode)

## Execution
```
ruby MindFreak.rb filename.bf [mode=interpreter|bytecode|bytecode2|rb|c] [bounds=500] [EOF=0|-1|any integer|unchanged]
```

The current implementation expects a program filename, execution mode, tape bounds and EOF value.
The C mode is the fastest, it requires a compiler.
The tape is bounded by default to ``500`` cells, make it ``0`` to support any size.
An unbounded tape is slower and C mode will use the default size to allocate the tape.
The main of this project is just an example of the API, all modes can be executed in sequence.

## API
[**MindFreak**](MindFreak.rb) is a module with 2 attributes:
- ``attr_reader :pointer``, position of the current cell for interpreted execution modes.
- ``attr_writer :debug``, print bytecode size when enabled.

The methods require a String containing the program and an Array or Hash to be used as tape.
The bytecode generated is an Array of Arrays and differ from the basic to the optimized version.
Input and output can be redirected from STDIN/STDOUT to objects that respond to ``getbyte``/``read`` and ``putc``/``print``, respectively, such as a StringIO object.
- ``check(program)`` is used to sanitize the input program and check if brackets are balanced, modifies the program string, returns ``nil``.
- ``run_interpreter(program, tape, eof = 0, input = STDIN, output = STDOUT)`` executes the slow interpreter, reading from input, writing to output while using the provided tape.
- ``run_bytecode(program, tape, eof = 0, input = STDIN, output = STDOUT)`` executes the bytecode interpreter, reading from input, writing to output while using the provided tape.
- ``run_bytecode2(program, tape, eof = 0, input = STDIN, output = STDOUT)`` executes the optimized bytecode interpreter, reading from input, writing to output while using the provided tape.
- ``to_ruby(program, tape = TAPE_DEFAULT_SIZE, eof = 0, input = 'STDIN', output = 'STDOUT')`` returns a String with a equivalent Ruby program. If tape is Array or Hash the string will not contain tape and pointer declaration so ``eval`` will use external variables, otherwise tape is interpreted as size.
- ``to_c(program, tape = TAPE_DEFAULT_SIZE, eof = 0, type = 'unsigned int')`` returns a String with an equivalent C program. The type contains the cell type being used. If no bounded tape is provided, tape is interpreted as size.
- ``bytecode(program)`` returns an Array with basic bytecodes.
- ``optimize(bytecode, blank_tape = false)`` returns an Array with the optimized bytecodes, which can be further optimized if the tape is blank.

The basic bytecode is described by the tuple ``[instruction, argument]``, in which:
- **instruction** corresponds to the byte value of <kbd>+</kbd><kbd>></kbd><kbd>.</kbd><kbd>,</kbd><kbd>[</kbd><kbd>]</kbd>;
- **argument** corresponds to the amount of times this instruction is used or the jump index in case of <kbd>[</kbd> or <kbd>]</kbd>.

Note that <kbd>-</kbd> and <kbd><</kbd> are represented by their counterparts with negative arguments.

The extended bytecode replaces <kbd>></kbd> with offset, adds a multiply instruction, defined by <kbd>*</kbd>, and more information to each bytecode.
It is described by the tuple ``[instruction, argument, offset, assign, multiplier]``, in which:
- **offset** is added to the current pointer;
- **assign** a cell value when used by <kbd>+</kbd> or <kbd>*</kbd>;
- **multiplier** multiplies a cell value when used by <kbd>*</kbd>, copy values with ``1``.

The [tests](tests/rorschach.rb) include several examples and can be used as a guide.

## Changelog
- Oct 2013
  - Created
  - Unbounded cell value
  - Bounded or unbounded tape
  - Interpret <kbd>+</kbd><kbd>-</kbd><kbd>></kbd><kbd><</kbd><kbd>.</kbd><kbd>,</kbd><kbd>[</kbd><kbd>]</kbd> as instructions, the rest as comments
  - Check brackets before execution
  - Output tape when interrupted
  - Object oriented style
  - Bytecode mode
  - Ruby Mode
- Dec 2013
  - Optimizations
- Feb 2015
  - C mode
- Sep 2015
  - File keep optional
  - Improve 1.8.7 compatibility
- Oct 2015
  - Module based
  - Tape input
  - Less instance variables
  - Select IO
  - Multiplication
  - Ruby and C methods generate code instead of execution
  - Multiplication optimization
  - Bytecode2 interpreter
  - Remove program and tape from instance variables
  - Remove setup
- Mar 2016
  - Retire 1.8.7
  -  Record only last byte from consecutive reads
- Jul 2016
  - Use default tape size if no tape is provided
- Mar 2019
  - Optimize read/write instructions
- Dec 2020
  - Fix jump index bytecode
- Mar 2021
  - Fix multiply followed by clear
  - Dead code elimination
  - Ruby tape
- Nov 2022
  - Clang tests
- Feb 2023
  - Support GCC and Clang
- Mar 2023
  - Optimize interpreter
  - Custom EOF
- Apr 2023
  - Dead jump elimination
  - C tape
- Jan 2024
  - Support unchanged cell by EOF
  - Remove forward from extended bytecode

## ToDo's
- Step-by-step/interactive mode, breakpoint
- Add examples

[Nayuki]: https://www.nayuki.io/page/optimizing-brainfuck-compiler