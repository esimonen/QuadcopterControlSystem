`include "tb_tasks.sv"
module QuadCopter_tb();
			
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

wire [7:0] LED;

//// Maybe define some localparams for command encoding ///

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                .MOSI(MOSI),.INT(INT),.frnt_ESC(frnt_ESC),.back_ESC(back_ESC),
				.left_ESC(left_ESC),.rght_ESC(rght_ESC));				  			
	 
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.LED(LED),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC));


//// Instantiate Master UART (mimics host commands) //////
RemoteComm iREMOTE(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                     .cmd(host_cmd), .data(data), .send_cmd(send_cmd),
					 .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					 .resp(resp), .clr_resp_rdy(clr_resp_rdy));
initial begin
    rst_n = 1;
    clk = 0;
    snd_cmd = 0;
    @(posedge clk);
        rst_n = 0;

    @(posedge clk); // wait a clock cycle
    @(negedge clk) rst_n = 1; // deassert reset
    
    // Call tasks

    // calibrate 
    $display("CALIBRATE");
    cmd2send = CAL;
    fork
        begin: set_cal_done
            repeat (500000) @(posedge clk);
            cal_done = 1;
            @(posedge clk);
            cal_done = 0;
        end
        begin
            send_packet();
            check_cmd_cfg_outputs();
            disable set_cal_done;
        end
    join   


    // set pitch 
    $display("Set Pitch");
    cmd2send = STPTCH;
    data2send = 16'hBEEF;
    send_packet();
    check_cmd_cfg_outputs();

    //check pitch is approaching desired
    repeat (2000000) @(posedge clk);

    // set roll 
    $display("Set Roll");
    cmd2send = STRLL;
    data2send = 16'h1F4B;
    send_packet();
    check_cmd_cfg_outputs();

    //check roll is approaching desired
    repeat (2000000) @(posedge clk);

    // set yaw 
    $display("Set Yaw");
    cmd2send = STYW;
    data2send = 16'h8DA0;
    send_packet();
    check_cmd_cfg_outputs();

    //check yaw is approaching desired
    repeat (2000000) @(posedge clk);

    // set thrst 
    $display("Set Thrust");
    cmd2send = STTHRST;
    data2send = 16'h0045;
    send_packet();
    check_cmd_cfg_outputs();

    // Emergency Land
    $display("Emergency Land");
    cmd2send = EMER;
    data2send = 16'h0000;
    send_packet();
    check_cmd_cfg_outputs();
    
    // Motors off
    $display("Motors Off");
    cmd2send = MTSOFF;
    send_packet();
    check_cmd_cfg_outputs();

    $stop;

end


always
    #10 clk = ~clk;

endmodule	
