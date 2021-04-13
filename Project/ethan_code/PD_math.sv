module PD_math(
	input                    clk,
	input                  rst_n,
	input                    vld,
	input  signed [15:0] desired,
	input  signed [15:0]  actual,
	output signed [9:0]    pterm,
	output signed [11:0]   dterm
);


	localparam D_QUEUE_DEPTH = 12;
	wire signed [16:0] err;							//actual-desired
	wire signed [9:0] err_sat; 						//saturated signal of err to 10 bits
	reg signed [9:0] prev_err [D_QUEUE_DEPTH-1:0];	//ff for deriving, becomes a queue of [9:0]
	wire signed [9:0] D_diff;						//diff between err_sat and prev_err
	wire signed [6:0] sat_dterm;					//		
	localparam signed coeff = 5'b00111;				//coefficient for dterm signed multiply

	//initial subtraction
	assign err = actual - desired;

	//diff saturation
	assign err_sat = err[16]?
			//if negative
			((|(~err[15:9]))? 10'b1000000000 : {1'b1,err[8:0]}) :
			//if positive
			((| err[15:9])  ? 10'b0111111111 : {1'b0,err[8:0]});

//dterm logic
	
	//ff logic
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			prev_err <= {D_QUEUE_DEPTH{'{10'h000}}}; //using packed vectors to simulate a vector of regs
		else if (vld)
			prev_err <= {prev_err[D_QUEUE_DEPTH-2:0], err_sat}; //using packed vectors like a bitshifter to work as a queue
		
	/*
	generate
		genvar i; //can be inside or outside
		for(i = 0; i < D_QUEUE_DEPTH; i++) begin
			if(!rst_n)
				prev_err[i] <= 10'h000;
			else if (vld)
				prev_err[i] <= (!i) ? err_sat : prev_err[i-1];
		end
	endgenerate
	*/




	//combinational logic
	assign D_diff = err_sat - prev_err[D_QUEUE_DEPTH-1];

	//saturate D_diff to 7 bits
	assign sat_dterm = D_diff[9]?
			//if negative
			((|(~D_diff[8:6]))? 7'b1000000 : {1'b1,D_diff[5:0]}) :
			//if positive
			((|D_diff[8:6])? 7'b0111111 : {1'b0,D_diff[5:0]});

	assign dterm = sat_dterm * coeff;

	//pterm logic
	assign pterm = {err_sat[9], err_sat[9:1]} + //add 1/2 of err sat to
				   { {3{err_sat[9]} }, err_sat[9:3]};//1/8 of err sat to form 5/8 of pterm with arithmetic shifting

endmodule