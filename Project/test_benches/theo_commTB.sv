module theo_CommTB();

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
  
  logic fail; // one-way flag to indicate if any test fails

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
					 
  //assert property (@(posedge clk) ~cmd_rdy |-> RX_TX == 1 and TX_RX == 1);


  initial begin
    clk = 0;
    cmd2send = 8'hA1;
    data2send = 16'hB2C3;
    resp = 8'hA5;
    send_cmd = 0;
    send_resp = 0;
    rst_n = 1;

    // reset system
    @(negedge clk);
    rst_n = 0;
    $display("RESET ASSERTING");
    @(negedge clk);
    rst_n = 1;

    // TEST 1: Send data from REMOTE to QUAD
    @(posedge clk);
    cmd2send = 8'hA1; // redundant assignment, but here for clarity
    data2send = 16'hB2C3;
    send_cmd = 1;
    $display("ASSERTING SEND_CMD");
    @(posedge clk);
    send_cmd = 0;
    
    fork
	begin: timeout_cmd_rdy_1
		repeat (1000000) @(posedge clk);
		$fatal("FATAL: Waiting for timeout_cmd_rdy_1");
	end
	begin
		@(posedge cmd_rdy);
		disable timeout_cmd_rdy_1;
	end
    join
    assert(cmd == 8'hA1) $display("(1) cmd GOOD");
    else begin
      $error("(1) cmd ERR: @posedge of cmd_rdy, iQUAD's cmd=%h, should have been %h", cmd, cmd2send);
      fail = 1;
    end
    if (data !== 16'hB2C3) begin
      fail = 1;
      $display("FAILURE: @posedge of cmd_rdy, iQUAD's data=%h, should have been %h", data, data2send);
    end

    // TEST 2: Send data from QUAD to REMOTE
    @(posedge clk);
    resp = 8'hA5;
    send_resp = 1'b1;
    @(posedge clk);
    send_resp = 1'b0;

    fork
    	begin: timeout_resp_sent_1
		repeat (1000000) @(posedge clk);
		$fatal("FATAL: Timed out waiting for timeout_resp_sent_1");
	end
	begin
		@(posedge resp_sent);
		disable timeout_resp_sent_1;
	end
    join
    if (respRcvd !== 8'hA5) begin
      fail = 1;
      $display("FAILURE: @posedge of resp_sent, iREMOTE's respRcvd=%h, should have been %h", respRcvd, resp);
    end

    // TEST 3: Send data from REMOTE to QUAD (again)
    @(posedge clk);
    cmd2send = 8'h23;
    data2send = 16'h0897;
    send_cmd = 1;
    $display("ASSERTING SEND_CMD");
    @(posedge clk);
    send_cmd = 0;

    fork
    	begin: timeout_cmd_rdy_2
		repeat (1000000) @(posedge clk);
		$fatal("FATAL: Timed out waiting for timeout_cmd_rdy_2");
	end
	begin
		@(posedge cmd_rdy);
		disable timeout_cmd_rdy_2;
	end
    join
    if (cmd !== 8'h23) begin
      fail = 1;
      $display("FAILURE: @posedge of cmd_rdy, iQUAD's cmd=%h, should have been %h", cmd, cmd2send);
    end
    if (data !== 16'h0897) begin
      fail = 1;
      $display("FAILURE: @posedge of cmd_rdy, iQUAD's data=%h, should have been %h", data, data2send);
    end

    // TEST 4: Send data from QUAD to REMOTE (again)
    @(posedge clk);
    resp = 8'h46;
    send_resp = 1'b1;
    @(posedge clk);
    send_resp = 1'b0;

    fork
    	begin: timeout_resp_rdy_2
		repeat (1000000) @(posedge clk);
		$fatal("FATAL: Timed out waiting fo timeout_resp_rdy_2");
	end
	begin
		@(posedge respRcvd);
		disable timeout_resp_rdy_2;
	end
    join

    if (respRcvd !== 8'h46) begin
      fail = 1;
      $display("FAILURE: @posedge of resp_sent, iREMOTE's respRcvd=%h, should have been %h", respRcvd, resp);
    end


    if (fail) $display("TEST(S) FAILED.");
    else $display("TESTS PASSED.");
    $finish;
	
  end
  
  always
    #5 clk = ~clk;

endmodule
