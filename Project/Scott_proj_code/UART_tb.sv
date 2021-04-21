module UART_tb();

	logic clk, rst_n, trmt; // 50 MHz clk, active low asynch reset, transmit signal
	logic [7:0] tx_data; // serial data to be transmitted
	logic TX; // serial data output
	logic tx_done; // done signal for serial transfer
	
	logic clr_rdy; // serial data input and knock down rdy signal
	logic [7:0] rx_data; // transmitted byte
	logic rdy; // signal to show when byte is recieved
	
	logic error; // signal to determine good test
	
	// instantiate DUTS
	UART_tx iDUT(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .TX(TX), .tx_done(tx_done));
	UART_rcv iDUT1(.clk(clk), .rst_n(rst_n), .RX(TX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));

	initial begin
		
		// set all outputs
		clk = 0;
		rst_n = 0;
		trmt = 0;
		clr_rdy = 0;
		error = 0;
		
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			tx_data = 8'hAA;
			trmt = 1; // enable trmt to start transmitting data
		end
		// check successful transmission
		@(posedge tx_done) begin
			$display("Done 1");
			rst_n = 0;
		end
		@(posedge clk); // wait a clock cycle
		@(negedge clk) rst_n = 1; // deassert reset
		@(posedge rdy) begin
			// check correct byte recieved and reset functions work
			if(rx_data !== 8'hAA) begin
				$display("%h transmitted, %h recieved", tx_data, rx_data);
				error = 1;
			end
			clr_rdy = 1;
			@(posedge clk); // wait a clock cycle
			if(rdy) begin
				$display("clr_rdy did not clear the ready signal");
				error = 1;
			end
			clr_rdy = 0;
			rst_n = 0;
		end
		
		
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			tx_data = 8'h44;
			trmt = 1; // enable trmt to start transmitting data
		end
		// check successful transmission
		@(posedge tx_done) begin
			$display("Done 2");
			rst_n = 0;
		end
		@(posedge clk); // wait a clock cycle
		@(negedge clk) rst_n = 1; // deassert reset
		@(posedge rdy) begin
			// check correct byte recieved and reset functions work
			if(rx_data !== 8'h44) begin
				$display("%h transmitted, %h recieved", tx_data, rx_data);
				error = 1;
			end
			clr_rdy = 1;
			@(posedge clk); // wait a clock cycle
			if(rdy) begin
				$display("clr_rdy did not clear the ready signal");
				error = 1;
			end
			clr_rdy = 0;
			rst_n = 0;
		end
		
		@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			tx_data = 8'h00;
			trmt = 1; // enable trmt to start transmitting data
		end
		// check successful transmission
		@(posedge tx_done) begin
			$display("Done 3");
			rst_n = 0;
		end
		@(posedge clk); // wait a clock cycle
		@(negedge clk) rst_n = 1; // deassert reset
		@(posedge rdy) begin
			// check correct byte recieved and reset functions work
			if(rx_data !== 8'h00) begin
				$display("%h transmitted, %h recieved", tx_data, rx_data);
				error = 1;
			end
			clr_rdy = 1;
			@(posedge clk); // wait a clock cycle
			if(rdy) begin
				$display("clr_rdy did not clear the ready signal");
				error = 1;
			end
			clr_rdy = 0;
			rst_n = 0;
		end
		
		if (!error)
			$display("YAHOO!! test passed");
		$stop;
	end
	always
		#5 clk = ~clk;

endmodule