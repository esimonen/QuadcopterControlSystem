module UART_comm(clk, rst_n, RX, TX, resp, send_resp, resp_sent, cmd_rdy, cmd, data, clr_cmd_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_resp;		// indicates to transmit 8-bit data (resp)
	input [7:0] resp;		// byte to transmit
	input clr_cmd_rdy;		// host asserts when command digested

	output TX;				// serial data output
	output resp_sent;		// indicates transmission of response complete
	output reg cmd_rdy;		// indicates 24-bit command has been received
	output reg [7:0] cmd;		// 8-bit opcode sent from host via BLE
	output reg [15:0] data;	// 16-bit parameter sent LSB first via BLE

	wire [7:0] rx_data;		// 8-bit data received from UART
	wire rx_rdy;			// indicates new 8-bit data ready from UART
	wire rx_rdy_posedge;	// output of posedge detector on rx_rdy used to transition SM

	////////////////////////////////////////////////////
	// declare any needed internal signals/registers //
	// below including any state definitions        //
	/////////////////////////////////////////////////
	
	// FSM signals
	typedef enum reg [1:0] { IDLE, READ_1, READ_2 } state_t;
	state_t state;
	state_t next_state;

	reg capture_cmd, capture_data_hi; // indicate which part of cmd to read
	reg clr_cmd_ready_i; // signal internal to FSM, sync-ly resets cmd_rdy
	reg set_cmd_rdy_i; // signal internal to FSM, sync-ly presets cmd_rdy

	reg rx_rdy_ff1, rx_rdy_ff2; // sequential flops used for posedge detect of rx_rdy

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	uart iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(resp), .trmt(send_resp),
			   .tx_done(resp_sent), .rx_data(rx_data), .rdy(rx_rdy), .clr_rdy(1'b0));
		
	////////////////////////////////
	// Implement UART_comm below //
	//////////////////////////////

	// double flop rx_rdy for positive edge detection
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			rx_rdy_ff1 <= 1'b0;
			rx_rdy_ff2 <= 1'b0;
		end
		else begin
			rx_rdy_ff1 <= rx_rdy;
			rx_rdy_ff2 <= rx_rdy_ff1;
		end
	assign rx_rdy_posedge = ~rx_rdy_ff2 & rx_rdy_ff1;

	// SR Flop to prevent cmd_rdy signal from glitching
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			cmd_rdy <= 1'b0;
		else if (set_cmd_rdy_i)
			cmd_rdy <= 1'b1;
		else if (clr_cmd_rdy || clr_cmd_ready_i)
			cmd_rdy <= 1'b0;
		// otherwise hold

	/***** Datapath *****/

	// muxed cmd byte register
	always_ff @(posedge clk)
		if (capture_cmd)
			cmd <= rx_data;
		// otherwise hold value
	
	// muxed data high byte register
	always_ff @(posedge clk)
		if (capture_data_hi)
			data[15:8] <= rx_data;
		// otherwise hold value
	
	// unconditionally pass this through, will be correct when
	// in READ2 state
	assign data[7:0] = rx_data;

	/***** FSM *****/

	// FSM state register
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;

	// FSM output logic and state transition logic
	always_comb begin
    	next_state = state;
    	capture_cmd = 1'b0;
    	capture_data_hi = 1'b0;
    	clr_cmd_ready_i = 1'b0;
		set_cmd_rdy_i = 1'b0;

    	case (state)
    		IDLE: begin
    	        if (rx_rdy_posedge) begin
					next_state = READ_1;
    	            capture_cmd = 1'b1;
    	            clr_cmd_ready_i = 1'b1;
    	        end
    	    end
    	    READ_1: begin
    	        if (rx_rdy_posedge) begin
					next_state = READ_2;
    		        capture_data_hi = 1'b1;
    	        end
    	    end
    	    default: begin // READ_2
   		        if (rx_rdy_posedge) begin
					next_state = IDLE;
        	        set_cmd_rdy_i = 1'b1;
    	        end
        	end
		endcase
	end

endmodule	