module PD_math_tb();

	logic clk, rst_n;		// 50 MHz clk and reset
	logic vld;				// new inertial sensor reading is valid
	logic [15:0] desired;	// desired inertial position
	logic [15:0] actual;	// actual inertial position
	logic [9:0] pterm;		// P of PD (signed)
	logic [11:0] dterm;		// D of PD (signed)

PD_math iDUT(.clk(clk), .rst_n(rst_n), .vld(vld), .desired(desired), .actual(actual), .pterm(pterm), .dterm(dterm));

initial begin
clk = 0;
rst_n = 1;
vld = 0;

// test 1 err sat is positive and does not saturate, d_diff also does not saturate
@(posedge clk) begin
	vld = 1;
	desired = 4;
	actual = 12;										//err_sat = 8
end
@(posedge clk) begin
	if(dterm !=0 || pterm != 5) begin				
		$display("error with pterm-1 or dterm-1");
		$stop;
	end
end

// test 2 testing with value present in FF, no saturation
@(posedge clk) begin
	actual = 40;
	desired = 24;										//err_sat =  16, prev_err = 8
end
@(negedge clk) begin
	if(dterm != 56 || pterm != 10) begin
		$display("error with dterm 2 or pterm 2");
		$stop;
	end
end

// test 3 err saturates negative, causes d_diff to saturate negative as well
@(negedge clk) begin
	rst_n = 0;
end
@(negedge clk) 	rst_n = 1;
@(posedge clk) begin
	actual = 16'b1000000000000000;
	desired = 0;										//err_sat = -512
end
@(posedge clk) begin
	if(dterm != 12'hE40) begin				//satured err and D_diff
		$display("error with dterm test 3");
		$stop;
	end
	if(pterm != 10'h2C0) begin
		$display("error with pterm test 3");
		$stop;
	end
end

// test 4 err saturates positive, causes d_diff to saturate positive as well
@(negedge clk) begin
	rst_n = 0;
end
@(negedge clk) 	rst_n = 1;
@(posedge clk) begin
	rst_n = 1;
	actual = 16'b0111111111111111;						// err_sat = 511
	desired = 0;
end
@(negedge clk) begin
	if(dterm != 12'h1B9) begin
		$display("error with dterm test 4");
		$stop;
	end
	if( pterm != 10'h13E) begin
		$display("error with pterm test 4");
		$stop;
	end
end

// test 5 err is negative but does not saturate
@(negedge clk) begin
	rst_n = 0;
end
@(posedge clk) begin
	rst_n = 1;
	actual = 0;
	desired = 8;
end
@(negedge clk) begin 
	if(dterm != 12'hFC8) begin
		$display("error with dterm test 5");
		$stop;
	end
	if(pterm != 10'h3FB) begin
		$display("error with pterm test 5");
		$stop;
	end
end

// test 6 err is 0
@(negedge clk) begin
	rst_n = 0;
end
@(posedge clk) begin
	rst_n = 1;
	actual = 10;
	desired = 10;
end
@(negedge clk) begin
	if(dterm != 0) begin
		$display("error with dterm test 6");
		$stop;
	end
	if(pterm != 0) begin
		$display("error with pterm test 6");
		$stop;
	end
end
$display("YAHOO tests passed");
$stop;
end

always begin
	#5 clk = ~clk;
end

endmodule