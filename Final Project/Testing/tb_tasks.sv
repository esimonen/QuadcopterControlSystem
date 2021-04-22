/*
 * Team:            The Moorons
 * Course:          ECE551
 * Professor:       Eric Hoffman
 * Team Members:    Ethan Simonen, Scott Woolf, Zach Berglund, Theo Hornung
 * Date:            4/14/2021
 */

// send_packet
//
// Fun little task to send a packet od data to our quadcopter (DUT)
//
// Requires no values for an input, but does read values from the tb:
// send_cmd:
// clk: clock singal 
// cmd_rdy:
// cal_done:
// resp_rdy:
task send_packet;
    
    begin
        // set the command to be sent to cmd_cfg through RemoteComm
        @(posedge QuadCopter_tb.clk) QuadCopter_tb.send_cmd = 1'b1;
        @(posedge QuadCopter_tb.clk) QuadCopter_tb.send_cmd = 1'b0;
        fork
            // wait until the command is received in the UART
            begin: timeout_cmd_rdy
                repeat (1000000) @(posedge QuadCopter_tb.clk);
                $error("Task 'send_packet' Failed: Waiting for cmd_rdy, never saw posedge");
                $stop;
            end
            begin
                @(posedge QuadCopter_tb.cmd_rdy);
                disable timeout_cmd_rdy;
            end
        join
        // if cmd_cfg is calibrating, wait until it is done until you check
        // that the response is correct
        if (QuadCopter_tb.inertial_cal) begin
            fork
                begin: timeout_cal
                    repeat (1000000) @(posedge QuadCopter_tb.clk);
                    $error("Task 'send_packet' Failed: Waiting for calibration to finish");
                    $stop;
                end
                begin
                    // wait for cal_done to pulse if calibrating
                    @(posedge QuadCopter_tb.cal_done);
                    disable timeout_cal;
                end
            join
        end
        // wait for the response to be ready at RemoteComm
        fork
            begin: timeout_resp_rdy
                repeat (1000000) @(posedge QuadCopter_tb.clk);
                $error("Task 'send_packet' Failed: Waiting for response at RemoteComm to be ready");
                $stop;
            end
            begin
                @(posedge QuadCopter_tb.resp_rdy);
                disable timeout_resp_rdy;
            end
        join
        // response is now ready
        assert(QuadCopter_tb.resp_out === 8'hA5)
        else begin
            $error("Task 'send_packet' Failed: Received incorrect response. Received %h, but expected %h.", QuadCopter_tb.resp, 8'hA5);
            $stop;
        end
    end

endtask

task check_cmd_cfg_outputs;

    // constants to make commands from uart more readable
    localparam SET_PTCH     = 8'h02;
    localparam SET_ROLL     = 8'h03;
    localparam SET_YAW      = 8'h04;
    localparam SET_THRST    = 8'h05;
    localparam CALIBRATE    = 8'h06;
    localparam EMER_LAND    = 8'h07;
    localparam MTRS_OFF     = 8'h08;
    begin
        
        case (QuadCopter_tb.cmd2send)
            SET_PTCH : begin 
                assert(QuadCopter_tb.resp_out === 8'hA5)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_PTCH, expected response of 8'A5, instead recieved %2h", QuadCopter_tb.resp_out);
                    $stop();
                end
                assert(QuadCopter_tb.d_ptch === QuadCopter_tb.data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_PTCH, expected response of %4h from data_in, instead recieved %4h", QuadCopter_tb.data2send, QuadCopter_tb.d_ptch);
                    $stop();
                end
            end
            SET_ROLL : begin
                assert(QuadCopter_tb.resp_out === 8'hA5)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_ROLL, expected response of 8'A5, instead recieved %2h", QuadCopter_tb.resp_out);
                    $stop();
                end
                assert(QuadCopter_tb.d_roll === QuadCopter_tb.data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_ROLL, expected response of %4h from data_in, instead recieved %4h", QuadCopter_tb.data2send, QuadCopter_tb.d_roll);
                    $stop();
                end
            end
            SET_YAW : begin
                assert(QuadCopter_tb.resp_out === 8'hA5)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_YAW, expected response of 8'A5, instead recieved %2h", QuadCopter_tb.resp_out);
                    $stop();
                end
                assert(QuadCopter_tb.d_yaw === QuadCopter_tb.data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_YAW, expected response of %4h from data_in, instead recieved %4h", QuadCopter_tb.data2send, QuadCopter_tb.d_yaw);
                    $stop();
                end
            end
            SET_THRST : begin
                assert(QuadCopter_tb.resp_out === 8'hA5) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_THRST, expected response of 8'A5, instead recieved %2h", QuadCopter_tb.resp_out);
                    $stop();
                end
                assert (QuadCopter_tb.thrst === QuadCopter_tb.data2send)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command SET_THRST, expected response of %3h from data_in, instead recieved %3h", QuadCopter_tb.data2send[8:0], QuadCopter_tb.thrst);
                    $stop();
                end
            end

            // don't need to check here, included for completeness
            CALIBRATE : begin
                // we do nothing!
            end

            // all values should be zero to stop quadcopter
            EMER_LAND : begin
                assert(QuadCopter_tb.d_ptch === 16'h0000)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_ptch, instead recieved %4h", QuadCopter_tb.d_ptch);
                    $stop();
                end
                assert(QuadCopter_tb.d_roll === 16'h0000)
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_roll, instead recieved %4h", QuadCopter_tb.d_roll);
                    $stop();
                end
                assert(QuadCopter_tb.d_yaw === 16'h0000) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for d_yaw, instead recieved %4h", QuadCopter_tb.d_yaw);
                    $stop();
                end
                assert(QuadCopter_tb.thrst === 9'h000) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Emergency land command sent: expected response of 16'h0000 for thrst, instead recieved %3h", QuadCopter_tb.thrst);
                    $stop();
                end
                assert(QuadCopter_tb.resp_out === 8'hA5) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Sent command EMER_LAND, expected response of 8'hA5, instead recieved %2h", QuadCopter_tb.resp);
                    $stop();
                end
            end

            // the motors off signal should be one
            MTRS_OFF : begin
                assert (QuadCopter_tb.motors_off === 1'b1) 
                else begin
                    $error("Task 'check_cmd_cfg_outputs' Failed: Motors off, expected response of 1'b1, instead received %1h", QuadCopter_tb.motors_off);
                    $stop();
                end
            end
        endcase
    end

endtask