`timescale 1ns/1ps
module SPI_mnrch_tb();
	
	logic clk, rst_n; // 50 MHz clock and asynchronous active low reset
	logic [15:0] wt_data, rd_data; // data to write to nemo and data recieved from nemo
	logic wrt; // write enable signal
	logic SS_n, SCLK; // active low serf select and serial clock
	logic MOSI, MISO; // transmitting bits, MOSI is from mnrch to nemo, MISO is from nemo to mnrch
	logic INT, done; // Interrupt output to tell when to read and done signal to tell when the SPI is done transmitting
	logic error; // error to dtermine if tests pass

	// instantiation of DUTs
	SPI_mnrch iDUT(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .wt_data(wt_data), .done(done), .rd_data(rd_data));
	SPI_iNEMO1 nemo(.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.INT(INT));
	
	initial begin
		error = 0; // innocent until proven guilty
		clk = 0; // start clk at 0
		
		// reset the system
		rst_n = 0;
		
		// Test WHO_AM_I register
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin // deassert reset and assert data on opposite edge of clock
			rst_n = 1;
			wt_data = 16'h8Fxx;
			wrt = 1;
		end
		// wait for the SPI to finish transmitting
		@(posedge done) begin
			// ensure the register has the correct value
			if(rd_data[7:0] !== 8'h6A) begin
				error = 1;
				$display("Expected WHO_AM_I reg to return 16'hxx6A, it returned %h", rd_data);
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		// test that nemo_setup asserts correctly
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin // deassert reset and assert data on opposite edge of clock 
			rst_n = 1;
			wt_data = 16'h0D02;
			wrt = 1;
		end
		// wait for SPI to finish transmitting
		@(posedge done) begin
			// ensure that nemo_setup goes high after writing to the correct register
			if(!nemo.NEMO_setup) begin
				error = 1;
				$display("Expected nemo_setup in SPI_iNEMO1 to go high");
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		// test that accessing ptchL deasserts INT and returns correct data
		@(posedge INT) begin // deassert reset and assert data on opposite edge of clock
			rst_n = 1;
			wt_data = 16'hA2xx;
			wrt = 1;
		end
		// wait for the SPI to finish transmitting
		@(posedge done) begin 
			// ensure correct data is in the register
			if(rd_data[7:0] !== 8'h63) begin
				error = 1;
				$display("Expected ptchL reg to return 16'hxx63, it returned %h", rd_data);
			end
			// ensure INT was deasserted
			if(INT) begin
				error = 1;
				$display("Expected INT to drop after reading ptchL reg");
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		
		// test that nemo_setup asserts correctly again
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin // deassert reset and assert data on opposite edge of clock 
			rst_n = 1;
			wt_data = 16'h0D02;
			wrt = 1;
		end
		// wait for SPI to finish transmitting
		@(posedge done) begin
			// ensure that nemo_setup goes high after writing to the correct register
			if(!nemo.NEMO_setup) begin
				error = 1;
				$display("Expected nemo_setup in SPI_iNEMO1 to go high");
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		// the next tests are a series of reads of random registers to ensure they return the correct data
		
		// test that ptchH reg returns the correct value
		@(posedge INT) begin // deassert reset and assert data on opposite edge of clock
			rst_n = 1;
			wt_data = 16'hA3xx;
			wrt = 1;
		end
		// wait for the SPI to finish transmitting
		@(posedge done) begin
			// ensure correct data
			if(rd_data[7:0] !== 8'hCD) begin
				error = 1;
				$display("Expected ptchH reg to return 16'hxxCD, it returned %h", rd_data);
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		// test that AZL reg returns the correct value
		@(posedge clk) begin // deassert reset and assert data on opposite edge of clock
			rst_n = 1;
			wt_data = 16'hACxx;
			wrt = 1;
		end
		// wait for the SPI to finish transmitting
		@(posedge done) begin 
			// ensure correct data
			if(rd_data[7:0] !== 8'h01) begin
				error = 1;
				$display("Expected AZL reg to return 16'hxx01, it returned %h", rd_data);
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		// test that AZL reg returns the correct value
		@(posedge clk) begin // deassert reset and assert data on opposite edge of clock
			rst_n = 1;
			wt_data = 16'hA8xx;
			wrt = 1;
		end
		// wait for the SPI to finish transmitting
		@(posedge done) begin 
			// ensure correct data
			if(rd_data[7:0] !== 8'h65) begin
				error = 1;
				$display("Expected AXL reg to return 16'hxx65, it returned %h", rd_data);
			end
			// reset the system
			rst_n = 0;
			// deassert wrt
			wrt = 0;
		end
		
		// if all tests pass, print a success message
		if(!error)
			$display("YAHOO!! Tests passed!");
		$stop;
	end
	
	always
		#5 clk = ~clk;
endmodule