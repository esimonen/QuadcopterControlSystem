/*
    Simple top-level testbench, calibrates copter and sets pitch, ensures correct basic functionality
*/ 
module QuadCopter_tb1();
		
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

    // set thrst 
    $display("Set Thrust");
    host_cmd = STTHRST;
    data = 16'h00FF;
    send_packet();
    check_cyclone_outputs();

    // set pitch 
    $display("Set Pitch");
    host_cmd = STPTCH;
    data = 16'h0100;
    send_packet();
    //check pitch is approaching desired
    check_cyclone_outputs();

    // at this point, all of the tests in this bench have passed
    $display("YAHOO!! Tests Passed!");
    $finish;
    
end

always
    #10 clk = ~clk;
    
`include "./tb_tasks.svh";
	
endmodule	

