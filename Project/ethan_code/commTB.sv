module CommTB();

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
  reg clr_resp_rdy;
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
  int timeout;
  int timeout2;
  wire resp_rdy;

  /////////////////////////////////////////
  // Instantiate UART_comm (Quadcopter) //
  ///////////////////////////////////////
  UART_comm iQUAD(.clk(clk), .rst_n(rst_n), .RX(RX_TX), .TX(TX_RX), .resp(resp), .send_resp(send_resp), .resp_sent(resp_sent),
            .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy));
			
  //////////////////////////////////////////////
  // Instantiate RemoteComm (remote control) //
  ////////////////////////////////////////////
  RemoteComm iREMOTE(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .TX(RX_TX), .cmd(cmd2send), .data(data2send), .send_cmd(send_cmd),
                     .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(respRcvd), .clr_resp_rdy(clr_resp_rdy));
					 
  initial begin
    //initialize all signals
    clk = 0;
    send_cmd = 0;
    send_resp = 0;
    clr_cmd_rdy = 0;

    //initial reset
    rst_n = 0;
    @ (negedge clk);
    rst_n = 1;
    repeat (2)@ (negedge clk);

    /*
     * Test 1: all bits low
     * CMD: 8'h00
     * DATA: 16'h0000
     * 
     * 
     */
    cmd2send  = 8'h00;
    data2send = 16'h0000;

    send_cmd = 1;
    @ (negedge clk);
    send_cmd = 0;
    @ (negedge clk);



    timeout = 0;
    while(!cmd_rdy) begin
      @(negedge clk);
      timeout += 1;
      if (timeout >= 500000) begin
        $display("Test 1: timeout, rdy not recieved after %6d clock cycles", timeout);
        $stop();
      end
    end

    if (data2send !== data) begin
      $display("Test 1: data recieved failed. Expected %4h Recieved %4h", data2send, data);
      $stop();
    end
    if (cmd2send !== cmd) begin
      $display("Test 1: cmd recieved failed. Expected %4h Recieved %4h", cmd2send, cmd);
      $stop();
    end


    while(!cmd_sent) @ (negedge clk);
    /*
     * Test 2: all bits high
     * CMD: 8'h00
     * DATA: 16'h0000
     * 
     * 
     */
     clr_cmd_rdy = 1;
     @(negedge clk);
     clr_cmd_rdy = 0;
     @(negedge clk);
    cmd2send  = 8'hFF;
    data2send = 16'hFFFF;
    @(negedge clk);
    send_cmd = 1;
    @ (negedge clk);
    send_cmd = 0;
    @ (negedge clk);
    timeout = 0;

    while(!cmd_rdy) begin
      @(negedge clk);
      timeout += 1;
      if (timeout >= 500000) begin
        $display("Test 2: timeout, rdy not recieved after %6d clock cycles", timeout);
        $stop();
      end
    end

    if (data2send !== data) begin
      $display("Test 2: data recieved failed. Expected %4h Recieved %4h", data2send, data);
      $stop();
    end
    if (cmd2send !== cmd) begin
      $display("Test 2: cmd recieved failed. Expected %4h Recieved %4h", cmd2send, cmd);
      $stop();
    end

    while(!cmd_sent) @ (negedge clk);
    /*
     * Test 3: 
     * send response
     * presp = 8'h00
     * 
     * 
     */
     clr_resp_rdy = 1;
     @(negedge clk);
     clr_resp_rdy = 0;
     @(negedge clk);
    resp  = 8'h00;
    @(negedge clk);
    send_resp = 1;
    @ (negedge clk);
    send_resp = 0;
    @ (negedge clk);
    timeout = 0;

    while(!resp_rdy) begin
      @(negedge clk);
      timeout += 1;
      if (timeout >= 500000) begin
        $display("Test 3: timeout, resp_rdy not recieved after %6d clock cycles", timeout);
        $stop();
      end
    end

    if (resp !== respRcvd) begin
      $display("Test 3: resp recieved failed. Expected %2h Recieved %2h", resp, respRcvd);
      $stop();
    end


    while(!resp_sent)@(negedge clk);
    /*
     * Test 4: 
     * send response
     * presp = 8'hCD
     * 
     * 
     */
     clr_resp_rdy = 1;
     @(negedge clk);
     clr_resp_rdy = 0;
     @(negedge clk);
    resp  = 8'hCD;
    @(negedge clk);
    send_resp = 1;
    @ (negedge clk);
    send_resp = 0;
    @ (negedge clk);
    timeout = 0;

    while(!resp_rdy) begin
      @(negedge clk);
      timeout += 1;
      if (timeout >= 500000) begin
        $display("Test 4: timeout, resp_rdy not recieved after %6d clock cycles", timeout);
        $stop();
      end
    end

    if (resp !== respRcvd) begin
      $display("Test 4: resp recieved failed. Expected %2h Recieved %2h", resp, respRcvd);
      $stop();
    end



    while(!resp_sent)@(negedge clk);
    /*
     *
     * Test 5: all bits low
     * CMD: 8'hB7
     * DATA: 16'hB73C
     * 
     * 
     */
    clr_cmd_rdy = 1;
    clr_resp_rdy = 1;
    @(negedge clk);
    clr_cmd_rdy = 0;
    clr_resp_rdy = 1;
    @(negedge clk);
    cmd2send  = 8'hB7;
    data2send = 16'hB73C;

    send_cmd = 1;
    @ (negedge clk);
    send_cmd = 0;
    @ (negedge clk);



    timeout = 0;
    while(!cmd_rdy) begin
      @(negedge clk);
      timeout += 1;
      if (timeout >= 500000) begin
        $display("Test 5: timeout, rdy not recieved after %6d clock cycles", timeout);
        $stop();
      end
    end

    if (data2send !== data) begin
      $display("Test 5: data recieved failed. Expected %4h Recieved %4h", data2send, data);
      $stop();
    end
    if (cmd2send !== cmd) begin
      $display("Test 5: cmd recieved failed. Expected %4h Recieved %4h", cmd2send, cmd);
      $stop();
    end


    while(!resp_sent)@(negedge clk);
    while(!cmd_sent) @(negedge clk);
    /* 
     * SUPER TEST - send and recieve data concurrently
     * Test 6: all bits low
     * CMD: 8'he5
     * DATA: 16'hc3b2
     * RESP: 8'67
     * 
     */
    clr_cmd_rdy = 1;
    clr_resp_rdy = 1;
    @(negedge clk);
    clr_resp_rdy = 0;
    clr_cmd_rdy = 0;
    @(negedge clk);
    cmd2send  = 8'he5;
    data2send = 16'hc3b2;
    resp = 8'h67;
    send_cmd = 1;
    send_resp = 1;
    @ (negedge clk);
    send_cmd = 0;
    send_resp = 0;
    @ (negedge clk);


    fork
      begin
        timeout = 0;
        while(!cmd_rdy) begin
          @(negedge clk);
          timeout += 1;
          if (timeout >= 500000) begin
            $display("Test 6: timeout, rdy not recieved after %6d clock cycles", timeout);
            $stop();
          end
        end

        if (data2send !== data) begin
          $display("Test 6: data recieved failed. Expected %4h Recieved %4h", data2send, data);
          $stop();
        end
        if (cmd2send !== cmd) begin
          $display("Test 6: cmd recieved failed. Expected %4h Recieved %4h", cmd2send, cmd);
          $stop();
        end
      end
      begin
        timeout2 = 0;
        while(!resp_rdy) begin
          @(negedge clk);
          timeout2 += 1;
          if (timeout2 >= 500000) begin
            $display("Test 6: timeout, resp_rdy not recieved after %6d clock cycles", timeout);
            $stop();
          end
        end

        if (resp !== respRcvd) begin
          $display("Test 6: resp recieved failed. Expected %2h Recieved %2h", resp, respRcvd);
          $stop();
        end        
      end
    join






    $display("yahoo! tests passed!");
    $stop();
  end
  
  always
    #5 clk = ~clk;

endmodule