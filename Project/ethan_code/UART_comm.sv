module UART_comm(clk, rst_n, RX, TX, resp, send_resp, resp_sent, cmd_rdy, cmd, data, clr_cmd_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_resp;		// indicates to transmit 8-bit data (resp)
	input [7:0] resp;		// byte to transmit
	input clr_cmd_rdy;		// host asserts when command digested

	output TX;				// serial data output
	output resp_sent;		// indicates transmission of response complete
	output reg cmd_rdy;		// indicates 24-bit command has been received
	output reg [7:0] cmd;	// 8-bit opcode sent from host via BLE
	output [15:0] data;	// 16-bit parameter sent LSB first via BLE

	wire [7:0] rx_data;		// 8-bit data received from UART
	wire rx_rdy;			// indicates new 8-bit data ready from UART
	wire rx_rdy_posedge;	// output of posedge detector on rx_rdy used to transition SM

	////////////////////////////////////////////////////
	// declare any needed internal signals/registers //
	// below including any state definitions        //
	/////////////////////////////////////////////////

	/*
	 * State Machine signals:
	 * CMD_RX:
	 * HIGH_DATA_RX:
	 * LOW_DATA_RX:
	 */
	typedef enum reg [1:0] {CMD_RX, HIGH_DATA_RX, LOW_DATA_RX} state_t;
	state_t state, nxt_state;

	logic     capture_cmd,	// high when capturing the command byte
		capture_high_byte,	// high when capturing the high data byte
				  clr_rdy,	// high when clearing UART rdy signal
			  set_cmd_rdy,	// high when setting the SR cmd_rdy signal
		   clr_cmd_rdy_sm;	// high when clearing the SR cmd_rdy signal
		
	//rx signals
	reg [7:0] high_byte;	// flops to hold the high byte recieved
	reg [1:0] rx_reg;
	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(resp), .trmt(send_resp),
			   .tx_done(resp_sent), .rx_data(rx_data), .rx_rdy(rx_rdy), .clr_rx_rdy(1'b0));
		
	////////////////////////////////
	// Implement UART_comm below //
	//////////////////////////////

	//rx_rdy_posedge logic
	always_ff @ (posedge clk) begin
		rx_reg[1] <= rx_rdy;
		rx_reg[0] <= rx_reg[1];
	end

	assign rx_rdy_posedge = rx_reg[1] & ~rx_reg[0];

	//State Machine
		always_ff @ (posedge clk, negedge rst_n) begin
			//if we reset, return to idle
			if (!rst_n)
				state <= CMD_RX;
			else
				state <= nxt_state;
		end

		always_comb begin
			capture_cmd       = 1'b0;
			capture_high_byte = 1'b0;
			clr_rdy			  = 1'b0;
			clr_cmd_rdy_sm    = 1'b0;
			set_cmd_rdy       = 1'b0;
			nxt_state = state;
			case(state)

				HIGH_DATA_RX: begin
					if (rx_rdy_posedge) begin
						capture_high_byte = 1'b1;
						clr_rdy = 1'b1;
						nxt_state = LOW_DATA_RX;
					end
				end

				LOW_DATA_RX: begin
					if (rx_rdy_posedge) begin
						clr_rdy     = 1'b1;
						//cmd_rdy     = 1'b1;
						set_cmd_rdy = 1'b1;
						nxt_state = CMD_RX;
					end
				end

				default: //CMD_RX (IDLE)
					if (rx_rdy_posedge) begin
						capture_cmd	   = 1'b1;
						clr_rdy 	   = 1'b1;
						clr_cmd_rdy_sm = 1'b1;
						nxt_state = HIGH_DATA_RX;
					end
			endcase
		end	

	//cmd logic
	always_ff @(posedge clk) begin

		if (capture_cmd) 

			cmd <= rx_data;
	end
	//rx logic
	always_ff @ (posedge clk) begin

		if(capture_high_byte)

			high_byte <= rx_data;
	end

	//output logic so high byte and low byte are combined for 2 byte data
	assign data = {high_byte, rx_data};

	//cmd_rdy logic: output logic to say when bytes are done being recieved.

	always_ff @ (posedge clk, negedge rst_n) begin

		if(!rst_n)
			cmd_rdy <= 1'b0;

		else if (clr_cmd_rdy_sm || clr_cmd_rdy)
			cmd_rdy <= 1'b0;

		else if (set_cmd_rdy)
			cmd_rdy <= 1'b1;

	end



endmodule	
