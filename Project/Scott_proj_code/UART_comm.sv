module UART_comm(clk, rst_n, RX, TX, resp, send_resp, resp_sent, cmd_rdy, cmd, data, clr_cmd_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_resp;		// indicates to transmit 8-bit data (resp)
	input [7:0] resp;		// byte to transmit
	input clr_cmd_rdy;		// host asserts when command digested

	output TX;				// serial data output
	output logic resp_sent;		// indicates transmission of response complete
	output logic cmd_rdy;		// indicates 24-bit command has been received
	output logic [7:0] cmd;		// 8-bit opcode sent from host via BLE
	output logic [15:0] data;	// 16-bit parameter sent LSB first via BLE

	wire [7:0] rx_data;		// 8-bit data received from UART
	logic rx_rdy;			// indicates new 8-bit data ready from UART
	logic rx_rdy_posedge;	// output of posedge detector on rx_rdy used to transition SM

	////////////////////////////////////////////////////
	// declare any needed internal signals/registers //
	// below including any state definitions        //
	/////////////////////////////////////////////////
	
	// State declaration
	typedef enum reg [1:0] {IDLE, GETMID, GETLOW} state;
	state cur_state, nxt_state;
	
	// declare internal signals used by SM
	logic [15:0] comm_bytes;
	logic capture_high, capture_mid;
	logic clr_rdy, set_cmd_rdy, clr_cmd_rdy_i;
	
	// internal signals used for rx_rdy - double flop signals and clear signal
	logic rx_rdy_int, rx_rdy_int1, clr_rx_rdy;

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(resp), .trmt(send_resp),
			   .tx_done(resp_sent), .rx_data(rx_data), .rx_rdy(rx_rdy), .clr_rx_rdy(1'b0));
		
	////////////////////////////////
	// Implement UART_comm below //
	//////////////////////////////
	
	// double flop rx_rdy
	always@(posedge clk) begin
		rx_rdy_int <= rx_rdy;
		rx_rdy_int1 <= rx_rdy_int;
	end
	
	// make rx_rdy posedge triggered
	assign rx_rdy_posedge = rx_rdy_int & ~rx_rdy_int1;
	
	// capture high byte
	always @(posedge clk) begin
		if(capture_high)
			comm_bytes[15:8] <= rx_data[7:0];
	end
	
	// capture mid byte
	always @(posedge clk) begin
		if(capture_mid)
			comm_bytes[7:0] <= rx_data[7:0];
	end
	
	// capture output
	assign data = {comm_bytes[7:0],rx_data[7:0]};
	assign cmd = comm_bytes[15:8];
	
	// set reset flop for cmd_rdy output, low on reset and clear, high when done transmitting
	always_ff @(posedge clk, negedge rst_n, posedge clr_cmd_rdy) begin
		if(!rst_n)
			cmd_rdy <= 1'b0;
		else if (set_cmd_rdy)  
			cmd_rdy <= 1'b1;
		else if (clr_cmd_rdy|clr_cmd_rdy_i)
			cmd_rdy <= 1'b0;
	end

  
    // infer state flops
	always_ff@(posedge clk, negedge rst_n) begin	
		if(!rst_n)
			cur_state <= IDLE;
		else
			cur_state <= nxt_state;
	end
	
	always_comb begin
		// default outputs
		capture_high = 0;
		capture_mid = 0;
		set_cmd_rdy = 0;
		clr_rdy = 0;
		nxt_state = cur_state;
		
		case(cur_state)
			// IDLE waits for reciever to have high byte
			IDLE : 
				if(rx_rdy_posedge) begin
					capture_high = 1;
					clr_rx_rdy = 1;
					nxt_state = GETMID;
				end
			// GETMID waits for mid byte
			GETMID : 
				if(rx_rdy_posedge) begin
					capture_mid = 1;
					clr_rx_rdy = 1;
					nxt_state = GETLOW;
				end
			// GETLOW waits for low byte and asserts ready when all bytes are recieved - goes back to IDLE for next cmd
			default :  // GETLOW state
				if(rx_rdy_posedge) begin
					set_cmd_rdy = 1;
					clr_rx_rdy = 1;
					nxt_state = IDLE;
				end
		endcase
	end

endmodule	