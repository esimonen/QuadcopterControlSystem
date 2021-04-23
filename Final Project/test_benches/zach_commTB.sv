module zach_CommTB();

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
	clk = 1'b0;
	rst_n = 1'b1;
	// reset
	@(negedge clk) begin
		rst_n = 1'b0;
	end
	@(negedge clk) begin
		rst_n = 1'b1;
	end
	// tests arbitrary stimulus and checks the same values return on the other side
	// apply stimulus to RemoteComm and wait for command to send
	@(negedge clk) begin
		cmd2send = 8'b10011001;
		data2send = 16'b1111000011110000;
		send_cmd = 1'b1;
	end
	@(negedge clk) begin
		send_cmd = 1'b0;
	end
	// means command has been received by UART_comm and can self check that it sent correctly
	@(posedge cmd_rdy) begin
		if(cmd !== cmd2send) begin
			$display("ERROR: command did not send correctly");
			$fatal;
		end
		if(data !== data2send) begin
			$display("ERROR: data did not send correctly");
			$fatal;
		end
	end
	
	//tests the clr_cmd_rdy function of UART_comm
	 @(posedge clk) begin
		clr_cmd_rdy = 1'b1;
	end
	@(posedge clk)
	@(posedge clk) begin
		if(cmd_rdy !== 0) begin
			$display("clr_command_rdy failed");
			$fatal;
		end
		else begin
			$display("clr_cmd_rdy passed");
		end
	end
	
	// tests the case of all 0's being sent and asserts it was sent correctly
	@(negedge clk) begin
		rst_n = 1'b0;
	end
	@(negedge clk) begin
		rst_n = 1'b1;
	end
	// apply stimulus to RemoteComm and wait for command to send
	@(negedge clk) begin
		cmd2send = 8'h00;
		data2send = 16'h0000;
		send_cmd = 1'b1;
	end
	@(negedge clk) begin
		send_cmd = 1'b0;
	end
	// means command has been received by UART_comm and can self check that it sent correctly
	@(posedge cmd_rdy) begin
		if(cmd !== cmd2send) begin
			$display("ERROR: command did not send correctly for all 0's");
			$fatal;
		end
		if(data !== data2send) begin
			$display("ERROR: data did not send correctly for all 0's");
			$fatal;
		end
		else begin
			$display("sending all 0's passed");
		end
	end
	
	// tests the case of all 1's being sent and asserts it was sent correctly
	@(negedge clk) begin
		rst_n = 1'b0;
	end
	@(negedge clk) begin
		rst_n = 1'b1;
	end
	// apply stimulus to RemoteComm and wait for command to send
	@(negedge clk) begin
		cmd2send = 8'hFF;
		data2send = 16'hFFFF;
		send_cmd = 1'b1;
	end
	@(negedge clk) begin
		send_cmd = 1'b0;
	end
	// means command has been received by UART_comm and can self check that it sent correctly
	@(posedge cmd_rdy) begin
		if(cmd !== cmd2send) begin
			$display("ERROR: command did not send correctlyfor all 1's");
			$fatal;
		end
		if(data !== data2send) begin
			$display("ERROR: data did not send correctly for all 1's");
			$fatal;
		end
		else begin
			$display("sending all 1's passed");
		end
	end
	$display("YAHOO all tests passed!");
	$finish;
  end
  
  always
    #5 clk = ~clk;

endmodule