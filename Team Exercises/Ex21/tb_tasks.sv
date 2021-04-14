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