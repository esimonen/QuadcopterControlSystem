module ESC_interface(clk, rst_n, wrt, SPEED, PWM);

	input logic clk, rst_n; // clock and active low reset
	input logic wrt; // initiates new pulse
	input logic [10:0] SPEED; // speed given from flight controller
	output reg PWM; // output to ESC for motor speed
	
	logic [12:0] speed_mult; // intermediate signal of speed * 3
	logic [13:0] speed_set, q; // intermediate signals of adding the base speed and speed_mult and then the output of the first flop
	logic reset; // reset signal for the 2nd flop (SR flop)
	
	localparam PCONST = 2'b11;     // decimal 3
	localparam ACONST = 13'h186A; // decimal 6250
	
	// add and multiply to get intermediate signals
	assign speed_mult = SPEED * PCONST;
	assign speed_set = speed_mult + ACONST;

	// logic for the first flop
	always_ff@(posedge clk, negedge rst_n, wrt) begin
		// asynch active low rst
		if(!rst_n)
			q <= 14'h0000;
		// first iteration q gets the result of addition from before
		else if (wrt)
			q <= speed_set;
		else
			// every other iteration we subtract
			q <= q - 1;
	end
	
	// assign reset to be high when all 0s
	assign reset = ~|q;
	
	// SR flop that assigns pwm
	always_ff@(posedge clk, negedge rst_n) begin
		// asynch active low reset
		if(!rst_n)
			PWM <= 1'b0;
		// assign pwm based on sr signals and hold otherwise
		else if (reset)  
			PWM <= 1'b0;
		else if (wrt)
			PWM <= 1'b1;
	end
endmodule
