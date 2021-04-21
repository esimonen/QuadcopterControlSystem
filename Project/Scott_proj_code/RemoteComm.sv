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
	// state declaration
	typedef enum reg [1:0] {IDLE, SENDCMD, SENDHIGH, SENDLOW} state;
	state cur_state, nxt_state;
	
	logic [1:0] sel; // select signal determines what to send 
	logic [7:0] high, low, tx_data; // high and low bytes and data to send
	logic trmt, tx_done; // transmit signal and transmit done signal
	
	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
			   .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy));
		   
	/////////////////////////////////
	// Implement RemoteComm Below //
	///////////////////////////////
	
	// flop to assign high byte 
	always@(posedge clk) begin
		if(send_cmd)
			high <= data[15:8];
	end
	
	// flop to assign low byte
	always@(posedge clk) begin
		if(send_cmd)
			low <= data[7:0];
	end
	
	// transmission data depends on what state - sel determines correct cmd to send
	assign tx_data = sel[1] ? cmd : (sel[0] ? high : low);


    // infer state flops
	always_ff@(posedge clk, negedge rst_n) begin	
		if(!rst_n)
			cur_state <= IDLE;
		else
			cur_state <= nxt_state;
	end


	always_comb begin
		// default outputs
		sel = sel;
		trmt = 0;
		cmd_sent = 0;
		nxt_state = cur_state;
		
		case(cur_state)
			// IDLE waits until told to send a command, sel chooses the cmd, not the high or low bytes
			IDLE : 
				if(send_cmd) begin
					sel = 2'b10;
					trmt = 1;
					nxt_state = SENDCMD;
				end
			// SENDCMD waits for the command to be done transmitting and then selects the high byte to send
			SENDCMD : 
				if(tx_done) begin
					sel = 2'b01;
					trmt = 1;
					nxt_state = SENDHIGH;
				end
			// SENDHIGH waits for the high byte to be done transmitting and then selects the low byte to send
			SENDHIGH :
				if(tx_done) begin
					sel = 2'b00;
					trmt = 1;
					nxt_state = SENDLOW;
				end
			// SENDLOW waits for the low byte to be done transmitting and then asserts the done signal
			default : // SENDLOW
				if(tx_done) begin
					cmd_sent = 1;
					nxt_state = IDLE;
				end
		endcase
	end
endmodule	
