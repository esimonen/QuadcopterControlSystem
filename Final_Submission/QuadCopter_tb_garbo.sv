module QuadCopter_tb_garbo();
		
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire RX,TX;
wire [7:0] resp;				// response from DUT
wire cmd_sent,resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] host_cmd;				// command host is sending to DUT
reg [15:0] data;				// data associated with command
reg send_cmd;					// asserted to initiate sending of command
reg clr_resp_rdy;				// asserted to knock down resp_rdy

//// Maybe define some localparams for command encoding ///

// local params for commands
localparam STPTCH   = 8'h02;
localparam STRLL    = 8'h03;
localparam STYW     = 8'h04;
localparam STTHRST  = 8'h05;
localparam CAL      = 8'h06;
localparam EMER     = 8'h07;
localparam MTSOFF   = 8'h08;

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                .MOSI(MOSI),.INT(INT),.frnt_ESC(frnt_ESC),.back_ESC(back_ESC),
				.left_ESC(left_ESC),.rght_ESC(rght_ESC));				  			
	 
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC));


//// Instantiate Master UART (mimics host commands) //////
RemoteComm iREMOTE(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                     .cmd(host_cmd), .data(data), .send_cmd(send_cmd),
					 .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					 .resp(resp), .clr_resp_rdy(clr_resp_rdy));
initial begin
    RST_n = 1;
    clk = 0;
    send_cmd = 0;
    @(posedge clk);
        RST_n = 0;

    @(posedge clk); // wait a clock cycle
    @(negedge clk) RST_n = 1; // deassert reset
    
    // Call tasks

    // calibrate 
    $display("CALIBRATE");
    host_cmd = CAL;
    send_packet();  

    $display("SENDING BAD COMMAND"); 
    host_cmd = 8'hED;
    data = 16'hBEEF;

    // set the command to be sent to cmd_cfg through RemoteComm
    @(posedge clk) send_cmd = 1'b1;
    @(posedge clk) send_cmd = 1'b0;

    // wait for the response to be ready at RemoteComm from the DUT
    fork
        begin: timeout_resp_rdy
            repeat (1000000) @(posedge clk);
            $fatal("send_packet Failed: Waiting for response at RemoteComm to be ready");
        end
        begin
            @(posedge resp_rdy);
            disable timeout_resp_rdy;
        end
    join
    // response is now ready, do not expect 8'hA5 as our expected response for a erroneous output
    if(resp !== 8'hA5) begin
        $display("YAHOO, garbage was perceived as garbage");
    end
    else begin
        $fatal("'send_packet' Failed: Received positive acknowledge with garbage command");
    end

    $finish;

end

always
    #10 clk = ~clk;
    
`include "./tb_tasks.svh";
	
endmodule	
