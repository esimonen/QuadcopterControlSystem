// Theo Hornung
// ece 551

module uart_tx(clk, rst_n, TX, trmt, tx_data, tx_done);

	input clk;
	input rst_n;
	input trmt; // asserted for 1 clk cycle, initiates transmission
	input [7:0] tx_data;
	output TX; // serial data output
	output reg tx_done; // asserted high when transmission done until next transmission started
	
	// FSM only needs idle state and transmitting state,
	// see FSM code at bottom
	typedef enum reg { IDLE, TRANSMITTING } state_t;
	
	state_t state; // current state of FSM
	state_t next_state; // next state of FSM
	
	reg set_done; // tx_done SR flop Set signal
	
	reg load; // when a new byte to be sent is given and needs to be parallel loaded
	wire shift; // when a shift should happen and the next bit is transmitted
	reg transmitting; // high while transmitting
	
	reg [8:0] tx_shift_reg; // flop signal for right shifter
	reg [3:0] bit_count; // flop signal for bit counter, only needs to count to 10dec
	reg [11:0] baud_count; 	// count through each bit
							// baud_count goes to (1/19200 baud rate) * 50MHz clk =
							// 2604dec => needs 12 bits
	
	// 3 datapath components
	// (1) Right shifter, shifts every time a 'shift' signal is asserted
	// (2) Baud counter, counts every clk cycle for a baud (1 bit)
	// (3) Bits shifted counter, inc every time a baud passes
	
	// (1) Right Shifter
	// outputs LSB of register to TX
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) // async low preset (uart idles to high)
			tx_shift_reg <= 9'h1ff;
		else if (load) // parallel load w/ uart format
			tx_shift_reg <= { tx_data, 1'b0 };
		else if (shift) // right shift data out, append 1 bc uart idle is high
			tx_shift_reg <= { 1'b1, tx_shift_reg[8:1] };
	// output is current LSB
	assign TX = tx_shift_reg[0];
	
	// (2) Baud Counter
	// output for when transmission done, which determines shift signal
	// *** ripped this from eric's example, trying to debug rn ***
	always @(posedge clk or negedge rst_n)
  		if (!rst_n)
    		baud_count <= 2604;
  		else if (load || shift)
    		baud_count <= 2604;			// baud of 19200 with 50MHz clk
  		else if (transmitting)
    		baud_count <= baud_count-1;		// only burn power incrementing if tranmitting
	assign shift = ~|baud_count;
	
	// (3) Bit Counter
	// output the num of bits transmitted
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			bit_count <= 4'h0;
		else if (load) // restart the counter when a new byte is loaded
			bit_count <= 4'h0;
		else if (shift) // inc counter when a new bit is sent
			bit_count <= bit_count + 1'b1;
	
	// SR flop for tx_done output signal
	// need this flop so tx_done doesn't glitch
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			tx_done <= 1'b0;
		else if (set_done)
			tx_done <= 1'b1;
		else if (trmt)
			tx_done <= 1'b0;
	
	// FSM state flop
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	
	// FSM state transition logic, output logic
	always_comb begin
		// default all signals assigned in this block to prevent latches
		next_state = state;
		load = 1'b0;
		transmitting = 1'b0;
		set_done = 1'b0;
		case(state)
			IDLE: begin
				if (trmt) begin
					next_state = TRANSMITTING;
					load = 1'b1;
				end
			end
			TRANSMITTING: begin
				// wait for 9 shifts
				if (bit_count == 4'hA) begin
					next_state = IDLE;
					set_done = 1'b1;
				end
				else begin
					next_state = TRANSMITTING;
					transmitting = 1'b1;
				end
			end 
			// all cases covered, no default needed
		endcase
	end
	
endmodule
