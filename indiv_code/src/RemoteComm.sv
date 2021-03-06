module RemoteComm(clk, rst_n, RX, TX, cmd, data, send_cmd, cmd_sent, resp_rdy, resp, clr_resp_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_cmd;			// indicates to tranmit 24-bit command (cmd)
	input [7:0] cmd;		// 8-bit command to send
	input [15:0] data;		// 16-bit data that accompanies command
	input clr_resp_rdy;		// asserted in test bench to knock down resp_rdy

	output TX;				// serial data output
	output reg cmd_sent;	// indicates transmission of command complete
	output resp_rdy;		// indicates 8-bit response has been received
	output [7:0] resp;		// 8-bit response from DUT

	reg [7:0] tx_data; // byte to be transmitted
	reg trmt; // high when transceiver should start transmitting
	wire tx_done;

	typedef enum reg[1:0] { IDLE, CMD, DATA_1, DATA_2 } state_t;
	state_t state;
	state_t next_state;

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	uart iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
			   .tx_done(tx_done), .rx_data(resp), .rdy(resp_rdy), .clr_rdy(clr_resp_rdy));
		   
	/////////////////////////////////
	// Implement RemoteComm Below //
	///////////////////////////////

	/***** FSM *****/

	// FSM state register
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	
	// FSM state transition and output logic
	always_comb begin
		// default to prevent latches
		next_state = state;
		trmt = 1'b0;
		cmd_sent = 1'b0;
		tx_data = 8'h00;
		case (state)
			IDLE: begin
				// start transmitting cmd byte
				if (send_cmd) begin
					tx_data = cmd;
					trmt = 1'b1;
					next_state = CMD;
				end
				// otherwise stay in idle state
			end
			CMD: begin
				// wait until cmd byte is tx'd, then start sending high data byte
				if (tx_done) begin
					tx_data = data[15:8];
					trmt = 1'b1;
					next_state = DATA_1;
				end
				// otherwise wait for tx of cmd byte to finish
			end
			DATA_1: begin
				// wait until high data byte is tx'd, then start sending low data byte
				if (tx_done) begin
					tx_data = data[7:0];
					trmt = 1'b1;
					next_state = DATA_2;
				end
				// otherwise wait for tx of high data byte to finish
			end
			default: begin // DATA_2
				if (tx_done) begin
					cmd_sent = 1'b1;
					next_state = IDLE;
				end
			end
		endcase
	end

endmodule	
