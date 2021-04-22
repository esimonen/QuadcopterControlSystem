// Theo Hornung
// ece 551
// ex11
module ESC_interface(clk, rst_n, wrt, SPEED, PWM);

    input clk, rst_n, wrt;
    input [10:0] SPEED;
    output reg PWM;

    localparam MIN_CLKS = 13'h186A;

    // internal signals
    wire [13:0] scaled_spd; // scaled speed signal to determine PWM period
    reg [13:0] count; // clks left before PWM sig goes low
    wire rst_pwm; // sync reset input to PWM sig flop

    // intermediate calculation for num of clock cycles for PWM signal
    assign scaled_spd = SPEED * 2'b11 + MIN_CLKS;

    // sync-ly reset PWM flop when count goes to all zeroes
    assign rst_pwm = ~|count;

    // counter logic w/ muxed input
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            count <= 0;
        else
            // subtract 1 and infer input mux to flop
            // can unconditionally subtract bc asserting wrt overwrites this flop, and even if
            // count wraps and rst_pwm is reasserted, it's just setting the PWM signal to zero again
            count <= wrt ? scaled_spd : count - 1'b1;

    // async reset SR flop w/ PWM sig output
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            PWM <= 1'b0;
        else if (rst_pwm)
            PWM <= 1'b0;
        else if (wrt)
            PWM <= 1'b1;
        // else PWM holds value

endmodule
