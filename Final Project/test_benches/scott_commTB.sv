module scott_CommTB();

  /////////////////////////////
  // stimulus declared next //
  ///////////////////////////
  reg clk,rst_n;
  reg [7:0] cmd2send;	// command remote is sending to Quadcopter
  reg [15:0] data2send;	// data remote is sending to Quadcopter
  reg send_cmd;			// initiates sending by remote to quad
  reg [7:0] resp;		// reponse copter sends back to remote
  reg send_resp;		// initiates reponse transmission
  reg clr_cmd_rdy;		// knocks down cmd_rdy flag
  
  /////////////////////////////////////
  // signals to monitor DUT(s) next //
  ///////////////////////////////////
  wire RX_TX;			// from RemoteComm to UART_comm
  wire TX_RX;			// from UART_comm to RemoteComm
  wire cmd_rdy;			// indicates new command ready from remote (use rise as time to check cmd/data)
  wire [7:0] cmd;		// the command byte
  wire [15:0] data;		// data that accompanies command
  wire cmd_sent;		// indicates remote is done sending command
  wire [7:0] respRcvd;	// response remote received from Quadcopter
  wire resp_sent;		// response has been sent (use rise of this as time to check resp).
  
  logic error;
  
  

  /////////////////////////////////////////
  // Instantiate UART_comm (Quadcopter) //
  ///////////////////////////////////////
  UART_comm iQUAD(.clk(clk), .rst_n(rst_n), .RX(RX_TX), .TX(TX_RX), .resp(resp), .send_resp(send_resp), .resp_sent(resp_sent),
            .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy));
			
  //////////////////////////////////////////////
  // Instantiate RemoteComm (remote control) //
  ////////////////////////////////////////////
  RemoteComm iREMOTE(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .TX(RX_TX), .cmd(cmd2send), .data(data2send), .send_cmd(send_cmd),
                     .cmd_sent(cmd_sent), .resp_rdy(), .resp(respRcvd), .clr_resp_rdy(1'b0));
					 
  initial begin
    
	error = 0;
	clk = 0;
	rst_n = 0;
	
	
	
	@(posedge clk); // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			data2send = 16'h0000;
			cmd2send = 8'h00;
			send_cmd = 1; // enable send_cmd to send the command and the data
		end
		@(posedge clk); // wait a clock cycle
		@(posedge cmd_rdy) begin
			// check correct cmd and data recieved
			if(cmd !== 8'h00) begin
				$display("%h sent, %h recieved", cmd2send, cmd);
				error = 1;
			end
			if(data !== 16'h0000) begin
				$display("%h sent, %h recieved", data2send, data);
				error = 1;
			end
			clr_cmd_rdy = 1;
			rst_n = 0;
	end
	
	@(posedge clk) clr_cmd_rdy = 0; // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			data2send = 16'h5577;
			cmd2send = 8'h99;
			send_cmd = 1; // enable send_cmd to send the command and the data
		end
		@(posedge clk); // wait a clock cycle
		@(posedge cmd_rdy) begin
			// check correct cmd and data recieved
			if(cmd !== 8'h99) begin
				$display("%h sent, %h recieved", cmd2send, cmd);
				error = 1;
			end
			if(data !== 16'h5577) begin
				$display("%h sent, %h recieved", data2send, data);
				error = 1;
			end
			clr_cmd_rdy = 1;
			rst_n = 0;
	end

	@(posedge clk) clr_cmd_rdy = 0; // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			data2send = 16'hFFFF;
			cmd2send = 8'hFF;
			send_cmd = 1; // enable send_cmd to send the command and the data
		end
		@(posedge clk); // wait a clock cycle
		@(posedge cmd_rdy) begin
			// check correct cmd and data recieved
			if(cmd !== 8'hFF) begin
				$display("%h sent, %h recieved", cmd2send, cmd);
				error = 1;
			end
			if(data !== 16'hFFFF) begin
				$display("%h sent, %h recieved", data2send, data);
				error = 1;
			end
			clr_cmd_rdy = 1;
			rst_n = 0;
	end


	@(posedge clk) clr_cmd_rdy = 0; // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			resp = 8'h00;
			send_resp = 1; // enable send_resp to send the response back to the remote
		end
		@(posedge clk) send_resp = 0; // wait a clock cycle
		@(posedge resp_sent) begin
			// check correct response recieved
			if(respRcvd !== 8'h00) begin
				$display("%h sent, %h recieved", resp, respRcvd);
				error = 1;
			end
			rst_n = 0;
	end
	
	@(posedge clk) clr_cmd_rdy = 0; // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			resp = 8'h55;
			send_resp = 1; // enable send_resp to send the response back to the remote
		end
		@(posedge clk) send_resp = 0; // wait a clock cycle
		@(posedge resp_sent) begin
			// check correct response recieved
			if(respRcvd !== 8'h55) begin
				$display("%h sent, %h recieved", resp, respRcvd);
				error = 1;
			end
			rst_n = 0;
	end
	
	@(posedge clk) clr_cmd_rdy = 0; // wait a clock cycle
		@(negedge clk) begin
			rst_n = 1; // deassert reset
			resp = 8'hFF;
			send_resp = 1; // enable send_resp to send the response back to the remote
		end
		@(posedge clk) send_resp = 0; // wait a clock cycle
		@(posedge resp_sent) begin
			// check correct response recieved
			if(respRcvd !== 8'hFF) begin
				$display("%h sent, %h recieved", resp, respRcvd);
				error = 1;
			end
			rst_n = 0;
	end
	
	
	if (!error)
			$display("YAHOO!! test passed");
	$finish;
  end
  
  always
    #5 clk = ~clk;

endmodule