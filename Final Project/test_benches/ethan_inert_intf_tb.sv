module ethan_inert_intf_tb();
	
	logic clk, rst_n;
	logic MISO;					// SPI input from inertial sensor
	logic INT;					// goes high when measurement ready
	logic strt_cal;				// from comand config.  Indicates we should start calibration
	  
	logic signed [15:0] ptch,roll,yaw;	// fusion corrected angles
	logic cal_done;						// indicates calibration is done
	logic vld;							// goes high for 1 clock when new outputs available
	logic SS_n,SCLK,MOSI;				// SPI outputs

	SPI_iNEMO2 iNemo(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT));
	inert_intf iDUT(.clk(clk),.rst_n(rst_n),.ptch(ptch),.roll(roll),.yaw(yaw),.strt_cal(strt_cal),.cal_done(cal_done),.vld(vld),.SS_n(SS_n),.SCLK(SCLK),
                  .MOSI(MOSI),.MISO(MISO),.INT(INT));

	initial begin
		rst_n = 1;
		clk = 0;
		strt_cal = 0;
		
		@(posedge clk); rst_n = 0; // wait a clock cycle;
		@(negedge clk) rst_n = 1; // deassert reset
		
		// check that NEMO_setup gets asserted in a reasonable time
		fork
			begin : timeout
				repeat(210000)@(posedge clk);
				$display("ERROR: timeout out waiting for NEMO_setup to assert");
				$fatal;
			end
			begin
				@(posedge iNemo.NEMO_setup);
				disable timeout;
			end
		join
	
		// assert strt_cal for 1 clock cycle
		@(posedge clk) strt_cal = 1;
		@(posedge clk) strt_cal = 0;
		
		// check that cal_done is asserted in a reasonable time
		fork
			begin : timeout1
				repeat(1000000)@(posedge clk);
				$display("ERROR: timeout out waiting for cal_done to assert");
				$fatal;
			end
			begin
				@(posedge cal_done);
				disable timeout1;
			end
		join
		
		// run for 8 million clocks
		repeat(8000000) @(posedge clk);
		
		$finish;
		
	end
	
	// clock
	always
		#5 clk = ~clk;
endmodule
