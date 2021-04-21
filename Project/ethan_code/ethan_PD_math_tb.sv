module ethan_PD_math_tb();
	reg clk, rst_n, vld;
	reg	signed [15:0] desired;
	reg signed[15:0] actual;
	wire signed [11:0] dout;
	wire signed [9:0] pout;
	int i;
	PD_math iDUT(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(desired),.actual(actual),.pterm(pout),.dterm(dout));
	always #5 clk = ~clk;// clk
	initial begin
		i = 0;
		clk = 0;
		rst_n=1;//active low
		vld=1;
		repeat(3)@(posedge clk);
		/*
		Test 0: -1 Input Negative
		*/
		desired= 16'hFFFF;
		actual = 16'hFFFF;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'd0)  begin 
				$display("Test %2d failed due to pterm. Expected 0 for neg max, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for neg max, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		
		/*
		Test 1: -1 actual Negative
		*/
		i=1;
		desired= 16'h0000;
		actual = 16'hFFFF;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'h2c0)  begin 
				$display("Test %2d failed due to pterm. Expected -320 for neg max actual, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for neg max actual, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		
		/*
		Test 2: -1 desired Negative
		*/
		i=2;
		desired= 16'hFFFF;
		actual = 16'h0000;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'h000)  begin 
				$display("Test %2d failed due to pterm. Expected 318 for neg max desired, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for neg max desired, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		
		/*
		Test 3: both zero
		*/
		i=3;
		desired= 16'h0000;
		actual = 16'h0000;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'd0)  begin 
				$display("Test %2d failed due to pterm. Expected 0 for all 0, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for all 0, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join

		/*
		Test 4: both max pos
		*/
		i=4;
		desired= 16'h7FFF;
		actual = 16'h7FFF;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'd0)  begin 
				$display("Test %2d failed due to pterm. Expected 0 for max pos, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for max pos, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		

	
		/*
		Test 5: actual max pos
		*/
		i=5;
		desired= 16'h0000;
		actual = 16'h7FFF;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'd318)  begin 
				$display("Test %2d failed due to pterm.expected 319, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for max pos, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join

		
		/*
		Test 6: desired max pos
		*/
		i=6;
		desired= 16'h7FFF;
		actual = 16'h0000;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'h2c0)  begin 
				$display("Test %2d failed due to pterm.expected 319, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for max pos, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join

		
		/*
		Test 7: both max neg
		*/
		i=7;
		desired= 16'h8000;
		actual = 16'h8000;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'd0)  begin 
				$display("Test %2d failed due to pterm.expected 0, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for max pos, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		

		
		/*
		Test 8: desired max neg
		*/
		i=8;
		desired= 16'h8000;
		actual = 16'h0000;
		repeat(3)@(posedge clk);
		fork
		  begin
			if(pout != 10'd318)  begin 
				$display("Test %2d failed due to pterm.expected 318, Received %h.",i,pout);
				$stop();
			end else if(dout != 10'd0) begin
				$display("Test %2d failed due to dterm. Expected 0 for max pos, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		
		/*
		Test 9: test dterm ff -large diff
		*/
		i=9;
		desired= 16'h0000;
		actual = 16'h0000;
		rst_n = 0;
		@(negedge clk);
		rst_n=1;
		@(negedge clk);
		@(negedge clk);
		desired= 16'h0000;
		actual = 16'h8000;
		@(posedge clk);
		actual=16'h0000;
		@(negedge clk);
		fork
		  begin
			if(dout != 10'h1c0) begin//overflow unaccounted for, this makes sense in our application
				$display("Test %2d failed due to dterm. Expected 1c0, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		
		/*
		Test 10: test dterm ff -small diff
		*/
		i=10;
		desired= 16'h0000;
		actual = 16'h0000;
		rst_n = 0;
		@(negedge clk);
		rst_n=1;
		@(negedge clk);
		@(negedge clk);
		desired= 16'h0000;
		actual = 16'h0001;
		@(posedge clk);
		actual=16'h0000;
		@(negedge clk);
		fork
		  begin
			if(dout != 10'd170) begin
				$display("Test %2d failed due to dterm. Expected 170, Received %h.",i,dout);
				$stop();
			end else $display("Test %2d Passed!",i);
		  end
		join
		
		$display("All Tests Passed! YAHOO!");
		$stop();
	end
endmodule