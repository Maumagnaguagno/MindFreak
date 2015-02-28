# MindFreak
A BrainFuck interpreter with bytecode support and language converter

Started this project during October 2013 to see something easy to parse and how much optimizations could be done. Ended up discovering a lot of crazy ideas about bytecode and macro optimizations.

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
