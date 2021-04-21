module PD_math(clk, rst_n, vld, desired, actual, pterm, dterm);
	
	input clk,rst_n, vld; // clock, asynch active low reset, valid signal to know when the flop is valid
	input signed [15:0] desired, actual; // 17 bit inputs to perform math on
	output signed [9:0] pterm; // 10 bit value that had proportional math done on it
	output signed [11:0] dterm; // 12 bit value that had derivative math done on it

	logic signed [16:0] err; // intermediate error term -- actual - desired
	logic signed [9:0] err_sat, D_diff; // intermediate signals - saturated error term and derivative term
	logic signed [6:0] D_diff_sat; // intermediate saturated derivative term
	localparam DTERM = 5'b00111; // constant to multply by to get dterm
	localparam D_QUEUE_DEPTH = 12;
	
	
	//////////////////////////////////////////
	// Declare prev_err_q which is queue   //
	// that will hold previous verions of //
	// error cor derivative calculation  //
	//////////////////////////////////////
	reg [9:0] prev_err_q [D_QUEUE_DEPTH-1:0];
	
	/////////////////////////////////////////
	//  Get derivative term for err math  //
	///////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			for(int i = 0; i < D_QUEUE_DEPTH; i++) begin
				prev_err_q[i] <= 10'h000;
			end
		end else if(vld) begin
			for(int i = 1; i < D_QUEUE_DEPTH; i++) begin
				prev_err_q[i] <= prev_err_q[i-1];
			end
			prev_err_q[0] <= err_sat[9:0];
		end
	end
	
	// get error and saturate for derivative math
	assign err = {actual[15],actual[15:0]} - {desired[15], desired[15:0]};
	assign err_sat = err[15] ? (&err[14:9] ? err[9:0] : 10'h200) : (|err[14:9] ? 10'h1FF : err[9:0]);
	assign D_diff = err_sat[9:0] - prev_err_q[D_QUEUE_DEPTH-1][9:0];
	assign D_diff_sat = D_diff[9] ? (&D_diff[8:6] ? D_diff[6:0] : 7'h40) : (|D_diff[8:6] ? 7'h3F : D_diff[6:0]);
	assign dterm = $signed(D_diff_sat) * $signed(DTERM);
	
	// use error and perform proportional math on it
	assign pterm = {err_sat[9], err_sat[9:1]} + {{3{err_sat[9]}}, err_sat[9:3]};
endmodule
