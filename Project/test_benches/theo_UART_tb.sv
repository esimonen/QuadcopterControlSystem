// Theo Hornung
// ece 551
// ex13
module theo_uart_tb();

	logic clk, rst_n;
	logic serial;
	logic trmt;
	logic [7:0] tx_data, rx_data;
	logic tx_done, rdy;
	logic clr_rdy;
	
	UART_tx iDUT_TX(.clk(clk), .rst_n(rst_n), .TX(serial), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));
	
	UART_rcv iDUT_RCV(.clk(clk), .rst_n(rst_n), .RX(serial), .rdy(rdy), .rx_data(rx_data), .clr_rdy(clr_rdy));
	
	initial begin
		clk = 0;
		tx_data = 8'h6A;
		trmt = 0;
		rst_n = 1;
		clr_rdy = 0;
		
		@(negedge clk)
		rst_n = 0;
		@(negedge clk);
		rst_n = 1;
		
		// (1) assert transmit signal for one clock cycle
		@(posedge clk);
		trmt = 1;
		@(posedge clk);
		trmt = 0;
		
		// (2) tx_done should go high at end of transmission
		// wait for transmission to be done
		
		// (3) receiver's rdy signal should go high soon after tx_done
		// receiver should be ready sometime after transmission finishes
		fork
			begin: timeout1;
				repeat (100000) @(posedge clk);
				$display("DID NOT RECEIVE POSEDGE RDY OR DID NOT RECEIVE POSEDGE TX_DONE");
				$fatal;
			end
			begin
				// we don't *really* know which will come first,
				// so wait for both of these with a timeout
				fork
					begin
						// (2)
						@(posedge tx_done);
						$display("TX DONE at time = %0t", $time);
					end
					begin
						// (3)
						@(posedge rdy);
						$display("RX DONE at time = %0t", $time);
					end
				join
				disable timeout1;
			end
		join
		
		
		// (1) continued
		// sent data should equal received data
		if (rx_data !== tx_data) begin
			$display("FAIL. Read rx_data=%h but should have been tx_data=%h", rx_data, tx_data);
			$fatal;
		end;
		
		// (4) test clr_rdy signal
		@(posedge clk); // wait some time
		clr_rdy = 1;
		@(posedge clk); // assert clr_rdy for a clock period
		clr_rdy = 0;
		@(posedge clk); // wait for clr_rdy to propogate through SR flop
		if (rdy === 1'b1) begin
			$display("FAIL. clr_rdy behavior is incorrect, rdy should have gone to 0");
			$fatal;
		end
		
		$display("ALL TESTS PASSED.");
		$finish;
	end

	always #5 clk = ~clk;

endmodule
