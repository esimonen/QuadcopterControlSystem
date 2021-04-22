module UART_tx(clk, rst_n, trmt, tx_data, TX, tx_done);

	input clk, rst_n, trmt; // 50 MHz clk, active low asynch reset, transmit signal
	input [7:0] tx_data; // serial data to be transmitted
	output logic TX; // serial data output
	output logic tx_done; // done signal for serial transfer
	
	logic [8:0] tx_shft_reg; // register to handle the shifting of the transmit data
	logic [11:0] baud_cnt; // register to keep track of the baud count
	logic [3:0] bit_cnt; // register to count how many shifts
	logic shift, transmitting, init, set_done; // intermediate signals used to kick off certain events
	
	// states
	typedef enum reg {IDLE, DONE} state;
	state cur_state, nxt_state;
	
	// TX shifting - shift on shift signal and fill on init signal, output TX when done with current operation
	always@(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tx_shft_reg <= 9'h1FF;
		else if(init)
			tx_shft_reg <= {tx_data[7:0],1'b0};
		else if(shift)
			tx_shft_reg <= {1'b1,tx_shft_reg[8:1]};
		TX <= tx_shft_reg[0];
	end
	
	// baud counting - inititialize to 0 on init and shift signals and count when the system is transmitting
	always @(posedge clk) begin
		if(init|shift)
			baud_cnt <= 12'h000;
		else if(transmitting)
			baud_cnt <= baud_cnt + 1;
	end
	
	assign shift = (baud_cnt == 12'hA2C);
	
	// counting shifts
	always @(posedge clk) begin
		if(init)
			bit_cnt <= 4'h0;
		else if(shift)
			bit_cnt <= bit_cnt + 1;
	end
	
	// set reset flop
	// set when done, reset on init
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tx_done <= 1'b0;
		else if (set_done)  
			tx_done <= 1'b1;
		else if (init)
			tx_done <= 1'b0;
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
		set_done = 0;
		init = 0;
		transmitting = 0;
		nxt_state = cur_state;
		
		// case statement for state transition and output logic
		case(cur_state)
			// IDLE state waits for transmitting to start
			IDLE : 
				if(trmt) begin
					init = 1;
					transmitting = 1;
					nxt_state = DONE;
				end
			default : // DONE  
			// DONE state waits for 10 shifts or keeps running if less than 10
				if(bit_cnt == 4'hA) begin
					set_done = 1;
					nxt_state = IDLE;
				end else
					transmitting = 1;
		endcase
	end
endmodule