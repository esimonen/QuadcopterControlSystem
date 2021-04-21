module zach_UART_tb();

logic clk;
logic rst_n;
logic trmt;
logic [7:0] tx_data;
logic TX;
logic tx_done;
logic clr_rdy;
logic [7:0] rx_data;
logic rdy;

// instantiate DUTs
UART_tx iDUT1(.clk(clk), .rst_n(rst_n), .trmt(trmt), .tx_data(tx_data), .TX(TX), .tx_done(tx_done));
UART_rcv iDUT2(.clk(clk), .rst_n(rst_n), .RX(TX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));

initial begin
// initialize logic signals
clk = 1'b0;
rst_n = 1'b1;
trmt= 1'b0;
@(negedge clk) begin	// reset
	rst_n = 1'b0;
end
@(negedge clk) begin
	rst_n = 1'b1;
end
@(negedge clk) begin	// apply stimulus to trasmitter
	trmt = 1'b1;
	tx_data = 8'b11100100;
end
@(negedge clk) begin
	trmt = 1'b0;
end
@(posedge rdy) begin	// assert that byte sent through trasmitter was sent and received successfully
	if(rx_data !== 8'b11100100) begin
		$display("error in first test");
		$stop;
	end
	clr_rdy = 1'b1;
end
@(negedge clk) begin	// reset
	rst_n = 1'b0;
end
@(negedge clk) begin
	clr_rdy = 1'b0;
	rst_n = 1'b1;
end
@(negedge clk) begin	// apply stimulus to trasmitter
	trmt = 1'b1;
	tx_data = 8'b00000000;
end
@(negedge clk) begin
	trmt = 1'b0;
end
@(posedge rdy) begin	// assert that byte sent through trasmitter was sent and received successfully
	if(rx_data !== 8'b00000000) begin
		$display("error in second test");
		$stop;
	end
	clr_rdy = 1'b1;
end
@(negedge clk) begin	// reset
	rst_n = 1'b0;
end
@(negedge clk) begin
	clr_rdy = 1'b0;
	rst_n = 1'b1;
end	
@(negedge clk) begin	// apply stimulus to trasmitter
	trmt = 1'b1;
	tx_data = 8'b11111111;
end
@(negedge clk) begin
	trmt = 1'b0;
end
@(posedge rdy) begin	// assert that byte sent through trasmitter was sent and received successfully
	if(rx_data !== 8'b11111111) begin
		$display("error in third test");
		$stop;
	end
	clr_rdy = 1'b1;
end

$display("WOOHOO all tests passed");
$stop;
end

// logic for clock
always begin
	#5 clk <= ~clk;
end
endmodule
