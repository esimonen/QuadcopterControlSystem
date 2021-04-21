module SPI_mnrch_tb();

	logic clk;
	logic rst_n;
	logic [15:0] wt_data;	// data being sent to inertial sensor or A2D converter
	logic wrt;				// high for 1 clock period to initiate SPI transaction
	logic [15:0] rd_data;	// data from SPI serf
	logic SS_n;				// active low serf select
	logic SCLK;				// serial clk 1/16 freq of clk
	logic done;				// asserted when SPI transaction is complete
	logic MOSI;				// serial data out from monarch
	logic MISO;				// serial data in to monarch
	logic INT;				// interrupt output signal of NEMO
	
	//instantiate DUTs
	SPI_mnrch iSPI_MNRCH(.clk(clk), .rst_n(rst_n), .wrt(wrt), .wt_data(wt_data), .MISO(MISO), .MOSI(MOSI), .SS_n(SS_n), .SCLK(SCLK), .done(done), .rd_data(rd_data));
	
	SPI_iNEMO1 iSPI_NEMO(.SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT));
	
	//begin testing
	initial begin
		// default signals
		clk = 1'b0;
		rst_n = 1'b1;
		@(negedge clk) begin
			rst_n = 1'b0;
		end
		// test 1 assert WHO_AM_I reads correctly
		@(negedge clk) begin
			rst_n = 1'b1;
			wt_data = 16'h8Fxx;		// should result in rd_data = 16'hxx6A
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		// wait for SPI transaction to finish then check result is correct
		@(posedge done) begin
			if(rd_data[7:0] !== 8'h6A) begin
				$display("initial read from constant register failed");
				$stop;
			end
		end
		// perform reset
		@(negedge clk) begin
			rst_n = 1'b0;
		end
		@(negedge clk) begin
			rst_n = 1'b1;
		end
		// test 2 perform read of ptchL should be 16'hxx63
		@(negedge clk) begin
			wt_data = 16'h0D02;		// write 02 at adress 0D to assert nemo_setup
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		@(posedge INT)				// wait for posedge INT to be able to read inertial data from 12 registers
		@(negedge clk) begin
			wt_data = 16'hA2xx;		// register holding pitchL value
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		// wait for SPI transaction to finish then check result is correct
		@(posedge done) begin
			if(rd_data[7:0] !== 8'h63) begin
				$display("read pitchL failed");
				$stop;
			end
		end
		
		// test 3 perfrom read of AXH from intertial data
		@(posedge INT)
		@(negedge clk) begin
			wt_data = 16'hA9xx;
			wrt = 1'b1;
		end
		@(negedge clk) begin
			wrt = 1'b0;
		end
		// wait for SPI transaction to finish then check result is correct
		@(posedge done) begin
			if(rd_data[7:0] !== 8'h84) begin
				$display("read AXH failed");
				$stop;
			end
		end
		$display("yahoo all tests passed");
		$stop;
	end
	
	// clock logic
	always begin
		#5 clk = ~clk;
	end
	
endmodule