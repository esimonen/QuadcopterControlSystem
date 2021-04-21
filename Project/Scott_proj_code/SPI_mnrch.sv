module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);

	input clk, rst_n; // 50 MHz clock and asynchronous active low reset
	input MISO; // data bit transmitted into mnrch
	input wrt; // write enable signal
	input [15:0] wt_data; // data to write to mnrch
	output logic SS_n; // serf select signal created in mnrch
	output SCLK, MOSI; // serial clk created in mnrch, data bit transmitted out of mnrch
	output logic done; // done transmitting signal
	output [15:0] rd_data; // data read in after transmit operation
	
	logic [4:0] bit_cntr; // counter to go to 16, counts the number of shifts
	logic [3:0] SCLK_div; // counter to determine when to shift based off of previous SCLKs
	logic [15:0] shft_reg; // register to hold data and shift in and out accordingly
	logic done16; // signal to tell SM that 16 bits have been transmitted
	
	logic shft, ld_SCLK, init, SCLK_set, set_done; // internal signals for SM control
	
	// declare states - IDLE for waiting, TRMT for transmitting, BCKDR to create back porch on SCLK
	typedef enum reg [1:0] {IDLE, TRMT, BCKDR} state;
	state cur_state, nxt_state;
	
	// flop to count number of shifts, reset on initialize signal
	always@(posedge clk) begin
		if(shft)
			bit_cntr <= bit_cntr + 1;
		if(init)
			bit_cntr <= 5'b00000;
	end
	
	// done16 is asserted when bit_counter = 16, after 16 shifts
	assign done16 = &bit_cntr[4];
	
	// flop to count SCLK and add accordingly, preset to 1011 (front porch) when being loaded
	always@(posedge clk) begin
		if(!ld_SCLK)
			SCLK_div <= 4'b1011;
		else
			SCLK_div <= SCLK_div + 1;
	end
	
	// SCLK is most significant bit of SCLK_div or set to 1 when not transmitting
	assign SCLK = SCLK_set ? 1'b1 : SCLK_div[3];
	
	// shift register to take in data and output data, loaded with data to write on initialization, shifts and takes in MISO on shft
	always@(posedge clk) begin
		if(init)
			shft_reg <= wt_data;
		else if(shft)
			shft_reg <= {shft_reg[14:0], MISO};
	end
	
	// data to output is what is left on shft_reg after transmission
	assign rd_data = shft_reg;
	// MOSI is always the MSB of the shifting register
	assign MOSI = shft_reg[15];
	
	// set/reset flop for SS_n, preset when the system is reset, high when finished transmitting, low on initialization
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			SS_n <= 1'b1;
		else if (set_done)  
			SS_n <= 1'b1;
		else if (init)
			SS_n <= 1'b0;
	end
	
	// set/reset flop for done signal, low on reset and initialization, high when done transmitting
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			done <= 1'b0;
		else if (set_done)  
			done <= 1'b1;
		else if (init)
			done <= 1'b0;
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
		init = 0;
		shft = 0;
		ld_SCLK = 1; // SCLK is high other than during transmission so it is active low
		set_done = 0;
		set_done = 0;
		SCLK_set = 0;
		nxt_state = cur_state;
		
		// case statement for state transition and output logic
		case(cur_state)
			// IDLE state waits for transmitting to start
			IDLE : begin
				SCLK_set = 1;
				if(wrt) begin
					ld_SCLK = 0;
					init = 1;
					nxt_state = TRMT;
				end
			end
			// TRMT state transmits data bit by bit until it has transmitted 16 times
			TRMT : begin
				if(SCLK_div == 4'b1001) begin
					shft = 1;
				end
				if(done16)
					nxt_state = BCKDR;
			end
			default : // BCKDR state
			// BCKDR state waits for SCLK to go high to create back porch on the signal and then transitions to IDLE to wait for new transmission
				if(SCLK) begin
					SCLK_set = 1;
					set_done = 1;
					nxt_state = IDLE;
				end
		endcase
	end
endmodule