module RemoteComm(clk, rst_n, RX, TX, cmd, data, send_cmd, cmd_sent, resp_rdy, resp, clr_resp_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_cmd;			// indicates to tranmit 24-bit command (cmd)
	input [7:0] cmd;		// 8-bit command to send
	input [15:0] data;		// 16-bit data that accompanies command
	input clr_resp_rdy;		// asserted in test bench to knock down resp_rdy

	output TX;				// serial data output
	output logic cmd_sent;	// indicates transmission of command complete
	output resp_rdy;		// indicates 8-bit response has been received
	output [7:0] resp;		// 8-bit response from DUT

	////////////////////////////////////////////////////
	// Declare any needed internal signals/registers //
	// below including state definitions            //
	/////////////////////////////////////////////////

	//state machine signals
	typedef enum reg [1:0] {SND_CMD, SND_HIGH, SND_LOW, IDLE} state_t;
	state_t state, nxt_state;

	logic [1:0] sel;
	logic trmt;

	reg [1:0] tx_reg;
	//wire tx_done_edge;	// output of posedge detector on rx_rdy used to transition SM

	//datapath signals
		reg [7:0] high_byte;
		reg [7:0] low_byte;
		wire[7:0] tx_data;
	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	uart iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
			   .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy));
		   
	/////////////////////////////////
	// Implement RemoteComm Below //
	///////////////////////////////

	//rising edge of tx_done logic
	//always_ff @ (posedge clk) begin
	///	tx_reg[1] <= tx_done;
	//	tx_reg[0] <= tx_reg[1];
	//end

	//assign tx_done_edge = tx_reg[1] & ~tx_reg[0];

	//state machine
	always_ff @ (posedge clk, negedge rst_n) begin
		//if we reset, return to idle
		if (!rst_n)
			state <= IDLE;
		if (clk)
			state <= nxt_state;
	end

	always_comb begin
		sel [1:0] = 2'b00;
		trmt = 0;
		nxt_state = state;
		cmd_sent = 1'b0;
		case(state)	

			SND_CMD: begin
				if(tx_done) begin
					sel = 2'b10;
					trmt = 1'b1;
					nxt_state = SND_HIGH;
				end
			end

			SND_HIGH: begin
				if (tx_done) begin
					sel = 2'b01;
					trmt = 1'b1;
					nxt_state = SND_LOW;
				end
			end

			SND_LOW: begin
				if (tx_done) begin
					cmd_sent = 1'b1;
					nxt_state = IDLE;
				end
			end


			default: begin//IDLE
				if (send_cmd) begin
					sel = 2'b00;
					trmt = 1'b1;
					nxt_state = SND_CMD;
				end
			end
		endcase
	end

	//tx_data logic
	assign tx_data = sel[1] ? high_byte :
				     sel[0] ? low_byte  :
				 		  	  cmd;
	//data flops
	always_ff @ (posedge clk) begin
		if (send_cmd) begin
			high_byte <= data[15:8];
			low_byte  <= data[7:0];
		end
	end

endmodule	
