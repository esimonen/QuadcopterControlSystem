module UART_comm(clk, rst_n, RX, TX, resp, send_resp, resp_sent, cmd_rdy, cmd, data, clr_cmd_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_resp;		// indicates to transmit 8-bit data (resp)
	input [7:0] resp;		// byte to transmit
	input clr_cmd_rdy;		// host asserts when command digested

	output TX;				// serial data output
	output resp_sent;		// indicates transmission of response complete
	output logic cmd_rdy;		// indicates 24-bit command has been received
	output logic [7:0] cmd;		// 8-bit opcode sent from host via BLE
	output logic [15:0] data;	// 16-bit parameter sent LSB first via BLE

	wire [7:0] rx_data;		// 8-bit data received from UART
	wire rx_rdy;			// indicates new 8-bit data ready from UART
	wire rx_rdy_posedge;	// output of posedge detector on rx_rdy used to transition SM

	////////////////////////////////////////////////////
	// declare any needed internal signals/registers //
	// below including any state definitions        //
	/////////////////////////////////////////////////
	logic set_cmd_rdy;
	logic store_cmd;
	logic store_data_high;
	logic clr_cmd_rdy_i;
	logic q1;
	logic q2;
	typedef enum logic [1:0] {IDLE, READ_DATA_HIGH, READ_DATA_LOW} state_t;
	state_t state, nxt_state;

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART	iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(resp), .trmt(send_resp),
			   .tx_done(resp_sent), .rx_data(rx_data), .rx_rdy(rx_rdy), .clr_rx_rdy(1'b0));
		
	////////////////////////////////
	// Implement UART_comm below //
	//////////////////////////////
	always_ff @(posedge clk) begin
		q1 <= rx_rdy;
		q2 <= q1;
	end
	assign rx_rdy_posedge = (q2 == 1'b0) && (q1 == 1'b1);
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			cmd_rdy <= 1'b0;
		end
		else if(set_cmd_rdy) begin
			cmd_rdy <= 1'b1;
		end
		else if(clr_cmd_rdy | clr_cmd_rdy_i) begin
			cmd_rdy <= 1'b0;
		end
	end
	
	always_ff @(posedge clk) begin
		if(store_cmd) begin
			cmd <= rx_data;
		end
	end
	
	always_ff @(posedge clk) begin
		if(store_data_high) begin
			data[15:8] = rx_data;
		end
	end
	
	assign data[7:0] = rx_data;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
		end
		else begin
			state <= nxt_state;
		end
	end
	
	always_comb begin
		nxt_state = state;
		store_cmd = 1'b0;
		store_data_high = 1'b0;
		set_cmd_rdy = 1'b0;
		clr_cmd_rdy_i = 1'b0;
		case(state)
			IDLE: begin
				if(rx_rdy_posedge) begin
					nxt_state = READ_DATA_HIGH;
					store_cmd = 1'b1;
					clr_cmd_rdy_i = 1'b1;
				end
			end
			READ_DATA_HIGH: begin
				if(rx_rdy_posedge) begin
					nxt_state = READ_DATA_LOW;
					store_data_high = 1'b1;
				end
			end
			default: begin
				if(rx_rdy_posedge) begin
					nxt_state = IDLE;
					set_cmd_rdy = 1'b1;
				end
			end
		endcase
	end	
endmodule	