module PD_math(
	input clk, rst_n,				// 50 MHz clk and reset
	input vld,						// new inertial sensor reading is valid
	input signed [15:0] desired,	// desired inertial position
	input signed [15:0] actual,		// actual inertial position
	output signed [9:0] pterm,		// P of PD (signed)
	output signed [11:0] dterm		// D of PD (signed)
);
	
	logic signed [16:0] actual_ext;		// 17 bit sign extended version of actual
	logic signed [16:0] desired_ext;	// 17 bit sign extended version of desired
	logic signed [16:0] err;			// difference in actual and desired
	logic signed [9:0] err_sat;			// 10 bit saturation of err
	logic signed [10:0] D_diff;			// Difference in err_sat now vs one clk cycle ago
	logic signed [6:0] D_diff_sat;		// 7 bit saturation of D_diff
	localparam COEFF = 5'b00111; 		// Constant to be multiplied by D_diff_sat
	localparam D_QUEUE_DEPTH = 4'b1100;	// number of FFs in chain for better derivitive queue
	logic signed [9:0] prev_ptch_err [0:D_QUEUE_DEPTH - 1];	//derivitive queue
	
	// sign extending actual and desired
	assign actual_ext = {actual[15],actual};
	assign desired_ext = {desired[15],desired};
	
	// calculating and saturating error
	assign err = actual_ext - desired_ext;
	assign err_sat = err[16] ? (&err[15:9] ? err[9:0] : 10'b1000000000) : (|err[15:9] ? 10'b0111111111 : err[9:0]);
	
	// pterm = 1/8 err sat + 1/2 err_sat = 5/8 err_sat
	assign pterm = (((err_sat) >>> 3) + ((err_sat) >>> 1));
	
	// better derivitive queue
	// creates chain of D_QUEUE_DEPTH FFs
	always @(posedge clk, negedge rst_n) begin
		for(integer i = 0; i < D_QUEUE_DEPTH; i = i + 1) begin
			if(!rst_n) begin
				prev_ptch_err[i] <= 10'b0000000000;
			end
			else if(vld) begin
				if(i == 0) begin
					prev_ptch_err[i] <= err_sat;
				end
				else begin
					prev_ptch_err[i] <= prev_ptch_err[i-1];
				end
			end
		end
	end

	// D_diff is the difference in err_sat now vs one clk cycle ago
	assign D_diff = err_sat - prev_ptch_err[D_QUEUE_DEPTH - 1];
	
	// Saturate D_diff to 7 bits
	assign D_diff_sat = D_diff[10] ? (&D_diff[9:6] ? D_diff[6:0] : 7'b1000000) : (|D_diff[9:6] ? 7'b0111111 : D_diff[6:0]);
	
	// Compute dterm
	assign dterm = $signed(D_diff_sat) * $signed(COEFF);
	
endmodule