module UART_rcv(
	input clk,				// 50MHz clock
	input rst_n,			// active low reset
	input RX,				// Serial data input
	input clr_rdy,			// Knocks downw rdy wihen asserted
	output [7:0] rx_data,	// Byte recieved
	output logic rdy		// Asserted when byte received. Stays high until start bit of next byte starts or clr_rdy is asserted.
);
logic init;					// Asserted once RX = 0, initializes bit count and baud count
logic shift;				// Asserted once baud_cnt = 0: increments bit_cnt, drops baud_cnt and shifts in RX
logic receiving;			// Asserted in RECEIVING state to save power usage when not in that state
logic set_rdy;				// Set on SR flop to assert rdy
logic sync_flop1;			// First of double flops used to synch RX to this systems clock
logic sync_flop2;			// Second of double flops used to synch RX to this systems clock
logic [3:0]bit_cnt;			// Counts up for each shift, asserts set_rdy once bit_cnt = 9
logic [11:0] baud_cnt;		// Counts down from 2604 or 1302 on systems clock
logic [7:0] rx_shift_reg;	// Holds current portion of transmitted byte
typedef enum logic {IDLE, RECEIVING} state_t;	// defining state names
state_t state, nxt_state;

// flip flop for bit_cnt initializes to 0 if init, or else checks for shift to increment
always_ff @(posedge clk) begin
	if(init) begin
		bit_cnt <= 4'b0000;
	end
	else if(shift) begin
		bit_cnt <= bit_cnt + 1;
	end
end

// flip flop for baud count, which counts down on clock from 1302 if init is asserted or 2604 if shift is asserted
always_ff @(posedge clk) begin
	if(init) begin
		baud_cnt <= 12'b010100010110;
	end
	else if(shift) begin
		baud_cnt <= 12'b101000101100;
	end
	else if(receiving) begin
		baud_cnt <= baud_cnt - 1;
	end
end

// assert if baud_cnt = 0
assign shift = (baud_cnt == 12'b000000000000);

// double flop to synch RX to system clock
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		sync_flop1 <= 1'b1;
		sync_flop2 <= 1'b1;
	end
	else begin
		sync_flop1 <= RX;
		sync_flop2 <= sync_flop1;
	end
end

// flip flop for shift register, takes in RX in msb
always_ff @(posedge clk) begin
	if(shift) begin
		rx_shift_reg <= {sync_flop2, rx_shift_reg[7:1]};
	end
end

// assign output
assign rx_data = rx_shift_reg;

// logic for setting next state and reset state
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		state <= IDLE;
	end
	else begin
		state <= nxt_state;
	end
end

// SM transition logic
always_comb begin
	// default all outputs
	nxt_state = IDLE;
	init = 1'b0;
	receiving = 1'b0;
	set_rdy = 1'b0;
	case(state)
		IDLE: begin		// check for RX = 0 to start receiving byte
			if(RX == 1'b0) begin
				nxt_state = RECEIVING;
				init = 1'b1;
				receiving = 1'b1;
			end
		end
		default: begin	// RECEIVING state: continue receiving until 9 bits have been received
			receiving = 1'b1;
			nxt_state = RECEIVING;
			if(bit_cnt == 9) begin
				set_rdy = 1'b1;
				nxt_state = IDLE;
			end
		end
	endcase
end

//SR flop with asynch reset for rdy: set by set_rdy, knocked down by clr_rdy and init
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		rdy <= 1'b0;
	end
	else if(set_rdy) begin
		rdy <= 1'b1;
	end
	else if(clr_rdy | init) begin
		rdy <= 1'b0;
	end
end

endmodule
