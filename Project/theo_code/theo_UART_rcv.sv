
// Theo Hornung
// ece 551
// ex13
module uart_rcv(clk, rst_n, RX, rdy, rx_data, clr_rdy);

	input clk;
	input rst_n;
	input RX; // serial data input
	input clr_rdy; // deasserts rdy signal
	output reg rdy; // when finished reading, ready for next byte
	output [7:0] rx_data; // holds the read byte
	
	// clocks in a single baud period
	localparam BAUD_CLKS = 12'hA2C; // 2604 dec
	localparam BAUD_CLKS_AND_HALF = 12'hF42; // 3912 dec
	
	typedef enum reg { IDLE, READING } state_t;
	
	state_t state;
	state_t next_state;
	
	reg rx_flopped, rx_stable; // single flopped RX, double flopped RX value
	
	reg [3:0] bit_count;
	reg [11:0] baud_count;  // count through each bit
							// baud_count goes to (1/19200 baud rate) * 50MHz clk =
							// 2604dec => needs 12 bits
	reg [8:0] shift_reg;

	wire shift; // high when the next shift should happen

	reg init; // high when starting a new read
	reg set_rdy; // high to assert rdy
	
	// double flop RX for metastability
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
			// preset high because uart idle is 1
			rx_flopped <= 1'b1;
			rx_stable <= 1'b1;
		end
		else begin
			rx_flopped <= RX;
			rx_stable <= rx_flopped;
		end
		
	// SR flop for rdy signal
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			rdy <= 1'b0;
		else if (set_rdy)
			rdy <= 1'b1;
		else if (init || clr_rdy)
			rdy <= 1'b0;
	
	// 3 datapath components
	// (1) Right Shifter
	// (2) Baud Counter
	// (3) Bits Shifted Counter
	
	// (1) Right Shifter
	always_ff @(posedge clk)
		if (shift)
			shift_reg <= { rx_stable, shift_reg[8:1] };
		// otherwise hold
	assign rx_data = shift_reg[7:0];
	
	// (2) Baud Counter
	always_ff @(posedge clk)
		if (init) // wait half a cycle to sample in the middle of the rx bit
			baud_count <= BAUD_CLKS_AND_HALF;
		else if (shift)
			baud_count <= BAUD_CLKS;
		else if (state == READING)
			baud_count <= baud_count - 1'b1;
		// otherwise hold
	// shift when baud count to zero
	assign shift = ~|baud_count;
	
	// (3) Bit Counter
	always_ff @(posedge clk)
		if (init)
			bit_count <= 4'h0;
		else if (shift)
			bit_count <= bit_count + 1'b1;
		// otherwise just hold
	
	/********FSM********/
	
	// FSM state flop
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	
	// FSM state transition logic and output logic
	always_comb begin
		// default signals to prevent unintended latches
		next_state = state;
		init = 1'b0;
		set_rdy = 1'b0;
		case (state)
			IDLE: begin
				// start reading when uart start (low) received
				if (!rx_stable) begin
					next_state = READING;
					init = 1'b1;
				end
			end
			READING: begin
				if (bit_count == 4'h9) begin
					next_state = IDLE;
					set_rdy = 1'b1;
				end
			end
		endcase
	end
endmodule