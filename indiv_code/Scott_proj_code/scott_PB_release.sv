module PB_release(clk, rst_n, PB, released);
	
	input logic PB, rst_n, clk; // clock, reset, and button inputs
	output logic released; // output signal from push button
	
	// intermediate signals
	logic pre1, pre2, pre3;
	
	// propagate the button signal through 3 FFs
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			pre1 <= 1'b0;
		else
			pre1 <= PB;
	end
	
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			pre2 <= 1'b0;
		else
			pre2 <= pre1;
	end
	
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			pre3 <= 1'b0;
		else
			pre3 <= pre2;
	end
	
	// assign the released signal to determine posedge from button
	assign released = pre2 & !pre3;
	



endmodule