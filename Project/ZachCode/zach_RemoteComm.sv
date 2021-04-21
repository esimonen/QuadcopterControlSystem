module RemoteComm(clk, rst_n, RX, TX, cmd, data, send_cmd, cmd_sent, resp_rdy, resp, clr_resp_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_cmd;			// indicates to tranmit 24-bit command (cmd)
	input [7:0] cmd;		// 8-bit command to send
	input [15:0] data;		// 16-bit data that accompanies command
	input clr_resp_rdy;		// asserted in test bench to knock down resp_rdy

	output TX;				// serial data output
	output logic cmd_sent;		// indicates transmission of command complete
	output resp_rdy;		// indicates 8-bit response has been received
	output [7:0] resp;		// 8-bit response from DUT

	////////////////////////////////////////////////////
	// Declare any needed internal signals/registers //
	// below including state definitions            //
	/////////////////////////////////////////////////
	logic [7:0] data_ff_high;		// flop holding high byte of data to transmit
	logic [7:0] data_ff_low;		// flop holding low byte of data to tranmit
	logic [1:0] sel;				// signal picking which signal to transmit (cmd, data high, data low)
	logic trmt;						// initiates UART transmission
	logic [7:0] tx_data;			// byte to tranmit by UART
	typedef enum logic [1:0] {IDLE, RCV_DATA_HIGH, RCV_DATA_LOW, SENT_SIGNAL} state_t;	// states definition
	state_t state, nxt_state;

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
			   .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy));
		   
	/////////////////////////////////
	// Implement RemoteComm Below //
	///////////////////////////////
	
	//updates value in data is send_cmd is asserted
	always_ff @(posedge clk) begin
		if(send_cmd) begin
			data_ff_high <= data[15:8];
			data_ff_low <= data[7:0];
		end
	end
	
	// Selects which byte to send using select signal
	assign tx_data = (sel == 2'b10) ? data_ff_high : ((sel == 2'b01) ? data_ff_low : cmd);
	
	// state transition logic
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
		end
		else begin
			state <= nxt_state;
		end
	end
	
	// State machine
	always_comb begin
		// default all outputs of SM
		nxt_state = state;
		trmt = 1'b0;
		sel = 2'b00;
		cmd_sent = 1'b0;
		case(state)
			IDLE: begin		// state 1: waits and begins sending cmd on send_cmd assertion
				if(send_cmd) begin
					nxt_state = RCV_DATA_HIGH;
					trmt = 1'b1;	//initializes new byte transmission
				end
			end
			RCV_DATA_HIGH: begin	// state 2: waits for cmd to finish sending, then sends high byte of data
				if(tx_done) begin
					nxt_state = RCV_DATA_LOW;
					trmt = 1'b1;	//initializes new byte transmission
					sel = 2'b10;	//updates signal being sent
				end
			end
			RCV_DATA_LOW: begin		// state 3: waits for high byte of data to finish sending then sends low byte of data
				if(tx_done) begin
					nxt_state = SENT_SIGNAL;
					trmt = 1'b1;	//initializes new byte transmission
					sel = 2'b01;	//updates signal being sent
				end
			end
			default: begin			// state 4: wait until low byte of data is sent through, then assert that it has been sent
				if(tx_done) begin
					nxt_state = IDLE;
					cmd_sent = 1'b1;
				end
			end
		endcase
	end
endmodule	
