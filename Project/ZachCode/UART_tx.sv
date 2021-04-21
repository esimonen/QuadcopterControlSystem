module UART_tx(
	input clk,				// 50MHz clock
	input rst_n,			// active low reset
	input trmt,				// Asserted for 1 clock to initiate transmission
	input [7:0] tx_data,	// Byte to transmit
	output TX,				// Serial data output
	output reg tx_done		// Asserted when byte is done transmitting, stays high until next byte transmitted
);
logic init;					// Asserted with tmrt, initializes flops to 0 and tx_data extended
logic transmitting;			// Asserted in TRANSMITTING state to save power when not in that state
logic shift;				// Asserted when baud count equals 2604, increments bit_cnt and shifts out a bit to TX
logic set_done;				// Set signal on SR flop for tx_done
logic [3:0] bit_cnt;		// counts up for each shift until it equals 9
logic [11:0] baud_cnt;		// counts up with system clock to 2604 which then asserts shift and drops it back to 0
logic [8:0] tx_shift_reg;	// holds shifted bits on tx_data
typedef enum logic {IDLE, TRANSMITTING} state_t;	// defining state names
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

// flip flop for baud_cnt, initializes to 0 if init or shift, if in the transmitting state increments its value on the clock
always_ff @(posedge clk) begin
	if(init|shift) begin
		baud_cnt <= 12'b000000000000;
	end
	else if(transmitting) begin
		baud_cnt <= baud_cnt + 1;
	end
end

// shift is asserted for one clock cycle once baud_cnt = 2604
assign shift = (baud_cnt == 12'b101000101100);

// flip flop with asynch preset for shift reg, initializes to tx_data with 0 appended at lsb, shifts right on assertion of shift
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		tx_shift_reg <= 9'b111111111;
	end
	if(init) begin
		tx_shift_reg <= {tx_data,1'b0};
	end
	else if(shift) begin
		tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
	end
end

// transmits lsb of tx_shift_reg
assign TX = tx_shift_reg[0];

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
	// default outputs and next state
	nxt_state = IDLE;
	init = 1'b0;
	transmitting = 1'b0;
	set_done = 1'b0;
	case(state)
		IDLE: begin	// check for trmt to start transmission
			if(trmt) begin
				init = 1'b1;
				nxt_state = TRANSMITTING;
			end
		end
		default: begin	// in TRANSMITTING: keep transmitting until bit_cnt = 9
			transmitting = 1'b1;
			nxt_state = TRANSMITTING;
			if(bit_cnt == 9) begin
				set_done = 1'b1;
				nxt_state = IDLE;
			end
		end
	endcase
end
		
// SR flop for tx_done with asynch reset. Sets if set_done is asserted, knocks down if init is asserted
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n) begin
		tx_done <= 1'b0;
	end
	if(set_done) begin
		tx_done <= 1'b1;
	end
	else if(init) begin
		tx_done <= 1'b0;
	end
end

endmodule