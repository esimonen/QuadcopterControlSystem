module reset_synch(clk, RST_n, rst_n);
    
    input clk;
    input RST_n; // async reset active low signal from FPGA push button
    output rst_n; // sync'd reset active low signal, goes high on neg edge of clock

    reg ff1, ff2;

    // use negedge triggered flops here so that we assert our sync'd active low reset rst_n
    // at the negedge of clock, which means we won't have a reset and posedge clk trigger
    // at the same of for any of the other flops in our system

    // flop 1
    always_ff @(negedge clk, negedge RST_n)
        if (!RST_N)
            ff2 <= 1'b0;
        else
            ff2 <= ff1;
    
    // flop 2
    always_ff @(negedge clk, negedge RST_n)
        if (!RST_N)
            ff1 <= 1'b0;
        else
            ff1 <= 1'b1;

endmodule