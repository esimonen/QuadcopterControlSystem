module inert_intf_tb();
	
	logic clk;
	logic MISO;					// SPI input from inertial sensor
	logic INT;					// goes high when measurement ready
	logic strt_cal;				// from comand config.  Indicates we should start calibration
	  
	logic [7:0] LED;            // output to LED array on fpga board
	logic SS_n,SCLK,MOSI;		// SPI outputs

    logic RST_n;    // simulated 'reset button' on fpga
    logic NEXT;     // simulated 'next button' on fpga

	SPI_iNEMO2 iNemo(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT));
	inert_intf_test iDUT(.clk(clk), .NEXT(NEXT), .RST_n(RST_n), .LED(LED), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT));

	initial begin
		clk = 0;
		RST_n = 1;
        NEXT = 1;

        @(posedge iNEMO2.POR_n); // wait for nemo to power up and setup
		repeat (2) @(posedge clk); RST_n = 0; // wait on push button's reset to sync
		repeat (2) @(posedge clk) NEXT = 0; // deassert reset
		
		// check that NEMO_setup gets asserted in a reasonable time
		fork
			begin : timeout
				repeat(210000)@(posedge clk);
				$display("ERROR: timeout out waiting for NEMO_setup to assert");
				$stop;
			end
			begin
				@(posedge iNemo.NEMO_setup);
				disable timeout;
			end
		join
		
		$stop;
		
	end
	
	// clock
	always
		#5 clk = ~clk;
endmodule
