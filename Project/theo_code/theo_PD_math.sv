// Theo Hornung
// ece 551
// ex16
module PD_math(clk, rst_n, vld, desired, actual, pterm, dterm);

    input clk;
    input rst_n; // active low async reset
    input vld; // if most recent reading is valid
    input [15:0] desired; // what we want the reading to be
    input [15:0] actual; // current reading
    output [9:0] pterm; // proportional PID term
    output [11:0] dterm; // derivative PID term

    // default depth of d_term err queue
    localparam D_QUEUE_DEPTH = 12;

    // params for signed multiply to produce dterm
    localparam DTERM = 5'b00111;
	localparam NEG_BOUND_7BIT = 7'h40;
	localparam POS_BOUND_7BIT = 7'h3F;

    // params for 10bit saturate for err_sat
    localparam NEG_BOUND_10BIT = 10'h200;
	localparam POS_BOUND_10BIT = 10'h1FF;

    //////////////////////////////////////////
    // Declare prev_err which is flop queue that //
    // will hold previous verion of error //
    ///////////////////////////////////////
    // [D_QUEUE_DEPTH-1] is the front of the queue
    // [0] is back of queue
    // elements get added to the back and move to the front
    reg [9:0] prev_err [0:D_QUEUE_DEPTH-1];

    // internal signals for actual - desired
    wire signed [16:0] err; // assigned difference between actual value and desired value
    wire [9:0] err_sat;
    wire signed [10:0] D_diff; // holds our pre-saturated derivative term
    wire [6:0] D_diff_sat;

    // calculate proportional error term
	// pterm = (5/8) * err_sat = (1/2 + 1/8) * err_sat (so ASR 1 + ASR 3);
	assign pterm = {err_sat[9], err_sat[9:1]} + {{3{err_sat[9]}}, err_sat[9:3]};

    // figure out saturated error term
    // sign extend for correct subtraction
    assign err = { actual[15], actual[15:0] } - { desired[15], desired[15:0] };

    // 17->10 bit saturation logic
    assign err_sat = err[16] ?
		    (&err[15:9] ? err[9:0] : NEG_BOUND_10BIT) :
		    (|err[15:9] ? POS_BOUND_10BIT : err[9:0]);
	
    // calculate derivative error term
    assign D_diff = {err_sat[9], err_sat } - {prev_err[D_QUEUE_DEPTH-1][9], prev_err[D_QUEUE_DEPTH-1] };
    assign D_diff_sat = D_diff[10] ? 
            (&D_diff[9:6] ?  D_diff[6:0] : NEG_BOUND_7BIT) :
			(|D_diff[9:6] ?  POS_BOUND_7BIT : D_diff[6:0]);
	// dterm = (saturate to 7-bits(D_diff) * DTERM)
	assign dterm = $signed(DTERM) * $signed(D_diff_sat);

    // infer and generate parameterizeable flops for d_term prev_err queue
    // will always have at least the [0] flop
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < D_QUEUE_DEPTH; i++)
                prev_err[i] <= 10'h000;
        end
        else if (vld) begin
            prev_err[0] <= err_sat;
            for (int i = 1; i < D_QUEUE_DEPTH; i++)
                prev_err[i] <= prev_err[i - 1];
        end
    end

endmodule
