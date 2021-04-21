module scott_ESC_interface_tb();
	
	logic clk, rst_n; // clock and active low reset
	logic wrt; // initiates new pulse
	logic [10:0] SPEED; // speed given from flight controller
	reg PWM; // output to ESC for motor speed
	logic error;

	//instantiate the dut
	ESC_interface iDUT(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(SPEED), .PWM(PWM));

	initial begin
		error = 0; // innocent until proven guilty
		
		
		clk = 0;
		rst_n = 0; // assert reset
		wrt = 0;
		
		SPEED = 11'h000; // 0 speed, should be 6250 clocks
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			wrt = 1; // enable wrt to load flops
		end
		@(posedge clk) begin
			wrt = 0; // disable wrt to start counting
			for(int i = 0; i < 6250; i++) begin // ensure PWM is high for the correct amount of time
				@(posedge clk);
				if(!PWM) begin
					$display("ERROR: PWM was high for %d clks when it should have been high for 6250", i);
					error = 1;
				end
			end
			
		end	
		// ensure that PWM drops
		@(posedge clk) begin
			if(PWM) begin
				$display("ERROR: PWM was high after 6250 clocks");
				error = 1;
			end
			rst_n = 0; // reset the flops after test is over
		end
		
		SPEED = 11'h228; // 552 speed, should be 7906 clocks
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			wrt = 1; // enable wrt to load flops
		end
		@(posedge clk) begin
			wrt = 0; // disable wrt to start counting
			for(int i = 0; i < 7906; i++) begin // ensure PWM is high for the correct amount of time
				@(posedge clk);
				if(!PWM) begin
					$display("ERROR: PWM was high for %d clks when it should have been high for 7906", i);
					error = 1;
				end
			end
		end
		// ensure that PWM drops
		@(posedge clk) begin
			if(PWM) begin
				$display("ERROR: PWM was high after 7906 clocks");
				error = 1;
			end
			rst_n = 0; // reset the flops after test is over
		end	
		
		
		SPEED = 11'h7FF; // 1047 speed, should be 12391 clocks
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			wrt = 1; // enable wrt to load flops
		end
		@(posedge clk) begin
			wrt = 0; // disable wrt to start counting
			for(int i = 0; i < 12391; i++) begin // ensure PWM is high for the correct amount of time
				@(posedge clk);
				if(!PWM) begin
					$display("ERROR: PWM was high for %d clks when it should have been high for 12391", i);
					error = 1;
				end
			end
		end	
		// ensure that PWM drops
		@(posedge clk) begin
			if(PWM) begin
				$display("ERROR: PWM was high after 12391 clocks");
				error = 1;
			end
			rst_n = 0; // reset the flops after test is over
		end
		
		// display good message if all tests passed
		if (!error)
			$display("YAHOO!! test passed");
	$stop;
	end
	
	// clock signal
	always
		#10 clk = ~clk;


endmodule