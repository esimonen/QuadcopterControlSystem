# QuadcopterControlSystem

Final Project for ECE 551:

Team Members:

Zach Berglund
Theo Hornung
Ethan Simonen
Scott Woolf

## TODOs:

- Polish synthesis script
  - Deal with high fanout of rst_n from QuadCopter.sv
  - do we need to specify drive strengths for anything
  - review the commented out lines we have in the script, figure out if they're necessary or helpful

- Full-chip test bench (ex23)
  - Do one testbench for each kind of command from RemoteComm to the whole DUT

- Test/debug everyone's modules
  - Need to figure out whose code works and whose doesn't
  - should try running everyone's modules against everyone else's test benches
 
- Post synthesis validation

- code coverage tests
