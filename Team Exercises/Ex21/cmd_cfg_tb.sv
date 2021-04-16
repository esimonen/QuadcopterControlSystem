`include "tb_tasks.sv"
/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/12/2021
 */
module cmd_cfg_tb();

reg clk;                // clock
reg rst_n;              // active low asynch reset
wire RX_TX;             // data transferred from UART_comm to RemoteComm
wire TX_RX;             // data transferred from RemoteComm to UART_comm
reg snd_cmd;            // indicates to tranmit 24-bit command (cmd)
reg cmd_sent;           // indicates transmission of command complete from RemoteComm to UART_comm
reg cmd_rdy;            // indicates 24-bit command has been received by UART_comm
reg [7:0] cmd;          // Command opcode
wire [15:0] data;       // the data read from the UART_comm 
reg clr_cmd_rdy;        // asserted when we want to clear the command ready signal from UART
reg [7:0] resp;         // the response that is being sent to the UART_comm 
wire send_resp;         // asserted when sending the response from cmd_cfg to UART_comm
reg [15:0] d_ptch;      // Holding register for desired pitch
reg [15:0] d_roll;      // Holding register for desired roll
reg [15:0] d_yaw;       // Holding register for desired yaw
reg [8:0] thrst;        // Holding register for thrust
reg strt_cal;           // Asserted when we want to start the calabration from the inertial integrator
reg inertial_cal;       // Held high during duration of calibration
reg cal_done;           // indicates the calibration is complete
reg motors_off;         // goes to ESC, shuts off motors
reg [7:0] cmd2send;     // command sent to the cmd_cfg
reg [15:0] data2send;   // data sent to the cmd_cfg
reg resp_rdy;
reg clr_resp_rdy;
reg resp_sent;
reg [7:0] resp_out;

//`include "tb_tasks.sv" // Tasks

// local params for commands
localparam STPTCH   = 8'h02;
localparam STRLL    = 8'h03;
localparam STYW     = 8'h04;
localparam STTHRST  = 8'h05;
localparam CAL      = 8'h06;
localparam EMER     = 8'h07;
localparam MTSOFF   = 8'h08;

// instantiate DUTs
RemoteComm iRemote(.clk(clk), .rst_n(rst_n), .RX(RX_TX), .TX(TX_RX), .cmd(cmd2send), 
 .data(data2send), .send_cmd(snd_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp_out),
 .clr_resp_rdy(clr_resp_rdy));

UART_comm iUART(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .TX(RX_TX), .resp(resp), 
 .send_resp(send_resp), .resp_sent(resp_sent), .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data),
 .clr_cmd_rdy(clr_cmd_rdy));

cmd_cfg icmd_cfg(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data),
 .clr_cmd_rdy(clr_cmd_rdy), .resp(resp), .send_resp(send_resp), .d_roll(d_roll),
 .d_yaw(d_yaw), .d_ptch(d_ptch), .thrst(thrst), .strt_cal(strt_cal),
 .inertial_cal(inertial_cal), .cal_done(cal_done), .motors_off(motors_off));

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

    // set roll 
    $display("Set Roll");
    cmd2send = STRLL;
    data2send = 16'h1F4B;
    send_packet();
    check_cmd_cfg_outputs();

    // set yaw 
    $display("Set Yaw");
    cmd2send = STYW;
    data2send = 16'h8DA0;
    send_packet();
    check_cmd_cfg_outputs();

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
    #5 clk = ~clk;

endmodule