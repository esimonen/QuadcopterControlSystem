# QuadcopterControlSystem

Final Project for ECE 551:

Team Members:

Zach Berglund
Theo Hornung
Ethan Simonen
Scott Woolf

## TODOs:

- Polish synthesis script
  - we can try messing around with some more compile combos to try to reduce area, but I think we've reached diminishing marginal returns there

- Full-chip test bench (ex23)
  - Finished the example tb that eric showed.
  - Make a few more test benches for different command combinations

- Test/debug everyone's modules (DONE)
 
- Post synthesis validation (TODO)
  - questasim is dumb, but it shouldn't be that bad
  - currently experiencing an issue with time scales???

- code coverage tests
  - finished first round. We're looking really good even with just the first full-chip tb
  - will want to make sure other tbs go through MOTORS_OFF and EMER_LAND commands
