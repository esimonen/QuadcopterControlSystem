# QuadcopterControlSystem

Final Project for ECE 551:

Team Members:

Zach Berglund
Theo Hornung
Ethan Simonen
Scott Woolf

## TODOs:

- Polish synthesis script (DONE FOR NOW)
  - we can try messing around with some more compile combos to try to reduce area, but I think we've reached diminishing marginal returns there

- Full-chip test bench
  - Finished the example tb that eric showed.
  - Make a few more test benches for different command combinations

- Test/debug everyone's modules (DONE)
 
- Post synthesis validation (TODO)
  - did once, but extremely slow to simulate in Questasim
  - TODO: talk to John a/o Eric to see if there's a good way to speed it up

- code coverage tests
  - finished first round. We're looking really good even with just the first full-chip tb
  - will want to make sure other tbs go through MOTORS_OFF and EMER_LAND commands

- move tb_tasks.svh? we might want to either put it in a different directory or change the reference in QuadCopter_tb.sv
