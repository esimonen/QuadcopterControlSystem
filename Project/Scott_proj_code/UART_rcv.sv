module UART_rcv(clk, rst_n, RX, clr_rdy, rx_data, rdy);

	input clk, rst_n; // 50 MHz clock and active low reset
	input RX, clr_rdy; // serial data input and knock down rdy signal
	output logic [7:0] rx_data; // transmitted byte
	output logic rdy; // signal to show when byte is recieved


	logic [8:0] rx_shft_reg; // register to handle the data being recieved
	logic [11:0] baud_cnt; // register to keep track of the baud count
	logic [3:0] bit_cnt; // register to count how many shifts
	logic shift, recieving, init, set_rdy; // intermediate signals to kick off certain events
	logic RXsynch, RXsynch1; // synchronizing intermediate logic for bit being recieved
	
	// state declaration
	typedef enum reg {IDLE, DONE} state;
	state cur_state, nxt_state;
	
	// double flop RX or preset
	always @(posedge clk, negedge rst_n) begin
		if(!rst_n) begin
			RXsynch <= 1'b1;     // preset
			RXsynch1 <= 1'b1;
		end
		else begin
			RXsynch <= RX;
			RXsynch1 <= RXsynch;
		end
	end
	
	// RX shifting
	always @(posedge clk) begin
		if(shift)
			rx_shft_reg <= {RXsynch1,rx_shft_reg[8:1]};
	end
	assign rx_data = rx_shft_reg[7:0];
	
	// baud counting
	// load with 1/2 baud on first iteration and 1 baud on others
	// count to 0 to count full baud
	always @(posedge clk) begin
		if(init)
			baud_cnt <= 12'h516;
		else if(shift)
			baud_cnt <= 12'hA2C;
		else if(recieving)
			baud_cnt <= baud_cnt - 1;
	end
	
	assign shift = (baud_cnt == 12'h000);
	
	
	// counting shifts
	always @(posedge clk) begin
		if(init)
			bit_cnt <= 4'h0;
		else if(shift)
			bit_cnt <= bit_cnt + 1;
	end
	
	// infer state flops
	always_ff@(posedge clk, negedge rst_n) begin	
		if(!rst_n)
			cur_state <= IDLE;
		else
			cur_state <= nxt_state;
	end
	
	// set reset flop
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			rdy <= 1'b0;
		else if (set_rdy)  
			rdy <= 1'b1;
		else if (init|clr_rdy)
			rdy <= 1'b0;
	end
	
	always_comb begin
		// default outputs
		set_rdy = 0;
		init = 0;
		recieving = 0;
		nxt_state = cur_state;
		
		// case statement for state transition and output logic
		case(cur_state)
		// IDLE waits for RX signal to drop to start recieving a byte
			IDLE : 
				if(!RX) begin
					init = 1;
					recieving = 1;
					nxt_state = DONE;
				end
			default : // DONE
			// DONE waits for 10 bits to be recieved or if the machine needs to keep running
				if(bit_cnt == 4'hA) begin
					set_rdy = 1;
					nxt_state = IDLE;
				end else
					recieving = 1;
		endcase
	end

endmodule
