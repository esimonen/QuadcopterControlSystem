/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/29/2021
 */

module reset_synch(clk, RST_n, rst_n);
    
    input clk;
    input RST_n; // async reset active low signal from FPGA push button
    output reg rst_n; // sync'd reset active low signal, goes high on neg edge of clock

    reg ff1;

    // use negedge triggered flops here so that we assert our sync'd active low reset rst_n
    // at the negedge of clock, which means we won't have a reset and posedge clk trigger
    // at the same of for any of the other flops in our system

    // flop 1
    always_ff @(negedge clk, negedge RST_n)
        if (!RST_n)
            rst_n <= 1'b0;
        else
            rst_n <= ff1;
    
    // flop 2
    always_ff @(negedge clk, negedge RST_n)
        if (!RST_n)
            ff1 <= 1'b0;
        else
            ff1 <= 1'b1;

endmodule