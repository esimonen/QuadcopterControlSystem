
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
wire snd_cmd;          // indicates to tranmit 24-bit command (cmd)
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
reg [7:0] thrst;        // Holding register for thrust
reg strt_cal;           // Asserted when we want to start the calabration from the inertial integrator
reg inertial_cal;       // Held high during duration of calibration
reg cal_done;           // indicates the calibration is complete
reg motors_off;         // goes to ESC, shuts off motors
reg [7:0] cmd2send;     // command sent to the cmd_cfg
reg [15:0] data2send;   // data sent to the cmd_cfg
reg resp_rdy;
reg clr_resp_rdy;
reg resp_sent;

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
 .data(data2send), .send_cmd(snd_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(resp),
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
    @(posedge clk);
        rst_n = 0;

    @(posedge clk); // wait a clock cycle
    @(negedge clk) rst_n = 1; // deassert reset
    
    // Call tasks

    // calibrate 
    $display("CALIBRATE");
    cmd2send = CAL;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);


    // set pitch 
    $display("Set Pitch");
    cmd2send = STPTCH;
    data2send = 16'hBEEF;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);

    // set roll 
    $display("Set Roll");
    cmd2send = STRLL;
    data2send = 16'h1F4B;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);

    // set yaw 
    $display("Set Yaw");
    cmd2send = STYW;
    data2send = 16'h8DA0;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);

    // set thrst 
    $display("Set Thrust");
    cmd2send = STTHRST;
    data2send = 16'h0045;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);

    // Emergency Land
    $display("Emergency Land");
    cmd2send = EMER;
    data2send = 16'h0000;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);
    
    // Motors off
    $display("Motors Off");
    cmd2send = MTSOFF;
    send_packet(cmd2send);
    check_cmd_cfg_outputs(cmd2send, data2send);

end


always
    #5 clk = ~clk;

endmodule

/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/14/2021
 */
task send_packet;
    input [7:0] cmd2send;
    
    begin
        // set the command to be sent to cmd_cfg through RemoteComm
        cmd = cmd2send;
        snd_cmd = 1'b1;
        fork
            // wait until the command is received in the UART
            begin: timeout_cmd_rdy
                repeat (1000000) @(posedge clk);
                $display("Task 'send_packet' Failed: Waiting for cmd_rdy, never saw posedge");
                $stop;
            end
            begin
                @(posedge cmd_rdy);
                disable timeout_cmd_rdy;
            end
        join
        // if cmd_cfg is calibrating, wait until it is done until you check
        // that the response is correct
        if (inertial_cal) begin
            fork
                begin: timeout_cal
                    repeat (1000000) @(posedge clk);
                    $display("Task 'send_packet' Failed: Waiting for calibration to finish");
                    $stop;
                end
                begin
                    // wait for cal_done to pulse if calibrating
                    @(posedge cal_done);
                    disable timeout_start_cal;
                end
            join
        end
        // wait for the response to be ready at RemoteComm
        fork
            begin: timeout_resp_rdy
                repeat (1000000) @(posedge clk);
                $display("Task 'send_packet' Failed: Waiting for response at RemoteComm to be ready");
                $stop;
            end
            begin
                @(posedge resp_rdy);
                disable timeout_start_cal;
            end
        join
        // response is now ready
        if (resp !== 8'hA5) begin
            $display("Task 'send_packet' Failed: Received incorrect response. Received %h, but expected %h.", resp, 8'hA5);
            $stop;
        end
    end

endtask

task check_cmd_cfg_outputs;
    input [7:0] cmd2send;
    input [15:0] data2send;

    // constants to make commands from uart more readable
    localparam SET_PTCH     = 8'h02;
    localparam SET_ROLL     = 8'h03;
    localparam SET_YAW      = 8'h04;
    localparam SET_THRST    = 8'h05;
    localparam CALIBRATE    = 8'h06;
    localparam EMER_LAND    = 8'h07;
    localparam MTRS_OFF     = 8'h08;
    begin
        
        case (cmd2send)
            SET_PTCH : begin
                if(resp !== 8'hA5) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_PTCH, expected response of 8'A5, instead recieved %2h", resp);
                    $stop();
                end
                if(d_ptch !== data2send) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_PTCH, expected response of %4h from data_in, instead recieved %4h", data_in, d_ptch);
                    $stop();
                end
            end
            SET_ROLL : begin
                if(resp !== 8'hA5) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_ROLL, expected response of 8'A5, instead recieved %2h", resp);
                    $stop();
                end
                if(d_roll !== data2send) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_ROLL, expected response of %4h from data_in, instead recieved %4h", data_in, d_roll);
                    $stop();
                end
            end
            SET_YAW : begin
                if(resp !== 8'hA5) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_YAW, expected response of 8'A5, instead recieved %2h", resp);
                    $stop();
                end
                if(d_yaw !== data2send) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_YAW, expected response of %4h from data_in, instead recieved %4h", data_in, d_yaw);
                    $stop();
                end
            end
            SET_THRST : begin
                if(resp !== 8'hA5) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_THRST, expected response of 8'A5, instead recieved %2h", resp);
                    $stop();
                end
                if(thrst !== data2send) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_THRST, expected response of %3h from data_in, instead recieved %3h", data_in[8:0], thrst);
                    $stop();
                end
            end

            // don't need to check here, included for completeness
            CALIBRATE : begin
                // we do nothing!
            end

            // all values should be zero to stop quadcopter
            EMER_LAND : begin
                if(d_ptch !== 16'h0000) begin
                    $display("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_ptch, instead recieved %4h", d_ptch);
                    $stop();
                end
                if(d_roll !== 16'h0000) begin
                    $display("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_roll, instead recieved %4h", d_roll);
                    $stop();
                end
                if(d_yaw !== 16'h0000) begin
                    $display("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_yaw, instead recieved %4h", d_yaw);
                    $stop();
                end
                if(thrst !== 9'h000) begin
                    $display("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for thrst, instead recieved %3h", thrst);
                    $stop();
                end
                if(resp !== 8'hA5) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Sent command EMER_LAND, expected response of 8'A5, instead recieved %2h", resp);
                    $stop();
                end
            end

            // the motors off signal should be one
            MTRS_OFF : begin
                if(motors_off !== 1'b1) begin
                    $display("Task 'check_cmd_cfg_outputs' Failed: Motors off, expected response of 1'b1, instead received %1h", motors_off);
                    $stop();
                end
            end
        endcase
    end

endtask